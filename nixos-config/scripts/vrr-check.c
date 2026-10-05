/*
 * vrr-check — DRM/KMS の VRR(Adaptive Sync) 対応チェックと実動作の実測
 *
 * 単一ファイル・外部依存なし(libc と Linux の DRM ioctl だけ)。Ubuntu でも
 * NixOS でも Arch でも同じように動く:
 *
 *   cc -O2 -o vrr-check vrr-check.c     # 必要なら -static を足す
 *   ./vrr-check                          # 既定 4 秒計測
 *   sudo ./vrr-check -s 10               # 長めに計測
 *
 * やること:
 *   1. 各コネクタの vrr_capable(ドライバが報告する VRR 対応)を読む
 *   2. そのコネクタが載っている CRTC の VRR_ENABLED(実際に有効か)を読む
 *   3. EDID の Monitor Range Limits から VRR の実レンジ(例 40-60Hz)を出す
 *   4. DRM_IOCTL_WAIT_VBLANK で vblank 周期を実測し、周期が動いているかを見る
 *      (VRR 無効なら モードのリフレッシュに固定。有効なら内容に追従して変動)
 *
 * root でなくても動く(session の logind ACL があれば /dev/dri/card0 を開ける)。
 * 何も書き換えない(read-only)。
 *
 * 出力は英語(そのまま他人に貼れるように)。コメントは日本語。
 */

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>

/* ---------------------------------------------------------------- DRM ABI */

#define DRM_IOCTL_BASE 'd'
#define DRM_IOC(dir, type, nr, size) \
	(((dir) << 30) | (((size) & 0x3fff) << 16) | (((type) & 0xff) << 8) | ((nr) & 0xff))
#define DRM_IOW(nr, size) DRM_IOC(1 /*WRITE*/, DRM_IOCTL_BASE, nr, size)
#define DRM_IOWR(nr, size) DRM_IOC(3 /*READ|WRITE*/, DRM_IOCTL_BASE, nr, size)

#define DRM_IOCTL_SET_CLIENT_CAP DRM_IOW(0x0d, 16)
#define DRM_IOCTL_WAIT_VBLANK DRM_IOWR(0x3a, 24)
#define DRM_IOCTL_MODE_GETRESOURCES DRM_IOWR(0xA0, 64)
#define DRM_IOCTL_MODE_GETCONNECTOR DRM_IOWR(0xA7, 80)
#define DRM_IOCTL_MODE_GETENCODER DRM_IOWR(0xA8, 20)
#define DRM_IOCTL_MODE_GETPROPERTY DRM_IOWR(0xAA, 64)
#define DRM_IOCTL_MODE_GETPROPBLOB DRM_IOWR(0xAC, 16)
#define DRM_IOCTL_MODE_OBJ_GETPROPERTIES DRM_IOWR(0xB9, 28)

#define DRM_VBLANK_RELATIVE 0x1
#define DRM_VBLANK_HIGH_CRTC_SHIFT 1

#define DRM_MODE_OBJECT_CRTC 0xcccccccc

#define MAX_CRTCS 32
#define MAX_CONNECTORS 32
#define MAX_PROPS 256
#define MAX_MODES 256

struct drm_mode_card_res {
	uint64_t fb_id_ptr, crtc_id_ptr, connector_id_ptr, encoder_id_ptr;
	uint32_t count_fbs, count_crtcs, count_connectors, count_encoders;
	uint32_t min_width, max_width, min_height, max_height;
};

struct drm_mode_get_connector {
	uint64_t encoders_ptr, modes_ptr, props_ptr, prop_values_ptr;
	uint32_t count_modes, count_props, count_encoders;
	uint32_t encoder_id, connector_id, connector_type, connector_type_id;
	uint32_t connection, mm_width, mm_height, subpixel, pad;
};

struct drm_mode_get_encoder {
	uint32_t encoder_id, encoder_type, crtc_id, possible_crtcs, possible_clones;
};

struct drm_mode_get_property {
	uint64_t values_ptr, enum_blob_ptr;
	uint32_t prop_id, flags;
	char name[32];
	uint32_t count_values, count_enum_blobs;
};

/* フィールド順は uapi どおり blob_id, length, data(ここを間違えると ENOENT になる) */
struct drm_mode_get_blob {
	uint32_t blob_id;
	uint32_t length;
	uint64_t data;
};

struct drm_set_client_cap {
	uint64_t capability;
	uint64_t value;
};

struct drm_mode_obj_get_properties {
	uint64_t props_ptr, prop_values_ptr;
	uint32_t count_props, obj_id, obj_type;
};

struct drm_wait_vblank_request {
	uint32_t type, sequence;
	unsigned long signal;
};

struct drm_wait_vblank_reply {
	uint32_t type, sequence;
	long tval_sec, tval_usec;
};

union drm_wait_vblank {
	struct drm_wait_vblank_request request;
	struct drm_wait_vblank_reply reply;
};

/* ------------------------------------------------------------- utilities */

static const char *conn_type_name(uint32_t t)
{
	switch (t) {
	case 1: return "VGA";
	case 7: return "LVDS";
	case 10: return "DP";
	case 11: return "HDMI-A";
	case 12: return "HDMI-B";
	case 14: return "eDP";
	case 15: return "Virtual";
	case 16: return "DSI";
	case 17: return "DPI";
	case 18: return "Writeback";
	case 20: return "USB-C";
	default: return "Unknown";
	}
}

static int ioctl_ret(int fd, unsigned long req, void *arg, const char *what)
{
	if (ioctl(fd, req, arg) < 0) {
		fprintf(stderr, "  ! %s failed: %s\n", what, strerror(errno));
		return -1;
	}
	return 0;
}

static double now_mono(void)
{
	struct timespec ts;

	clock_gettime(CLOCK_MONOTONIC, &ts);
	return ts.tv_sec + ts.tv_nsec / 1e9;
}

/* getresource でコネクタ/CRTC/エンコーダの id を集める */
static int get_resources(int fd, uint32_t *crtcs, uint32_t *n_crtcs,
			 uint32_t *conns, uint32_t *n_conns)
{
	struct drm_mode_card_res res;
	uint32_t crtcs_tmp[MAX_CRTCS] = { 0 }, conns_tmp[MAX_CONNECTORS] = { 0 };

	memset(&res, 0, sizeof(res));
	if (ioctl_ret(fd, DRM_IOCTL_MODE_GETRESOURCES, &res, "GETRESOURCES"))
		return -1;
	if (res.count_crtcs > MAX_CRTCS || res.count_connectors > MAX_CONNECTORS) {
		fprintf(stderr, "  ! too many crtcs/connectors (%u/%u)\n",
			res.count_crtcs, res.count_connectors);
		return -1;
	}
	res.crtc_id_ptr = (uint64_t)(uintptr_t)crtcs_tmp;
	res.connector_id_ptr = (uint64_t)(uintptr_t)conns_tmp;
	res.count_crtcs = MAX_CRTCS;
	res.count_connectors = MAX_CONNECTORS;
	res.count_fbs = 0;
	res.count_encoders = 0;
	res.encoder_id_ptr = 0;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_GETRESOURCES, &res, "GETRESOURCES(2)"))
		return -1;
	*n_crtcs = res.count_crtcs;
	*n_conns = res.count_connectors;
	memcpy(crtcs, crtcs_tmp, sizeof(uint32_t) * *n_crtcs);
	memcpy(conns, conns_tmp, sizeof(uint32_t) * *n_conns);
	return 0;
}

/* プロパティ id → 名前。name は 32 バイト固定 */
static int get_prop_name(int fd, uint32_t id, char *out, size_t outsz, uint32_t *flags)
{
	struct drm_mode_get_property p;

	memset(&p, 0, sizeof(p));
	p.prop_id = id;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_GETPROPERTY, &p, "GETPROPERTY"))
		return -1;
	snprintf(out, outsz, "%s", p.name);
	if (flags)
		*flags = p.flags;
	return 0;
}

/* オブジェクト(コネクタ/CRTC)のプロパティと値を取る */
static int obj_get_props(int fd, uint32_t obj_id, uint32_t obj_type,
			 uint32_t *props, uint64_t *vals, uint32_t *n)
{
	struct drm_mode_obj_get_properties op;
	uint32_t props_tmp[MAX_PROPS] = { 0 };
	uint64_t vals_tmp[MAX_PROPS] = { 0 };

	memset(&op, 0, sizeof(op));
	op.obj_id = obj_id;
	op.obj_type = obj_type;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_OBJ_GETPROPERTIES, &op, "OBJ_GETPROPERTIES"))
		return -1;
	if (op.count_props > MAX_PROPS)
		return -1;
	op.props_ptr = (uint64_t)(uintptr_t)props_tmp;
	op.prop_values_ptr = (uint64_t)(uintptr_t)vals_tmp;
	op.count_props = MAX_PROPS;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_OBJ_GETPROPERTIES, &op, "OBJ_GETPROPERTIES(2)"))
		return -1;
	*n = op.count_props;
	memcpy(props, props_tmp, sizeof(uint32_t) * *n);
	memcpy(vals, vals_tmp, sizeof(uint64_t) * *n);
	return 0;
}

/* プロパティ名から値を引く。見つからなければ -1 */
static int props_lookup(int fd, const uint32_t *props, const uint64_t *vals, uint32_t n,
			const char *want, uint64_t *out, int *flags_out)
{
	uint32_t i;

	for (i = 0; i < n; i++) {
		char name[64];
		uint32_t flags = 0;

		if (get_prop_name(fd, props[i], name, sizeof(name), &flags) < 0)
			continue;
		if (strcmp(name, want) == 0) {
			if (out)
				*out = vals[i];
			if (flags_out)
				*flags_out = (int)flags;
			return 0;
		}
	}
	return -1;
}

static int get_connector(int fd, uint32_t id, uint32_t *type, uint32_t *type_id,
			 uint32_t *conn_state, uint32_t *encoder_id,
			 uint32_t *props, uint64_t *vals, uint32_t *n_props)
{
	struct drm_mode_get_connector c;
	uint32_t props_tmp[MAX_PROPS] = { 0 };
	uint64_t vals_tmp[MAX_PROPS] = { 0 };

	memset(&c, 0, sizeof(c));
	c.connector_id = id;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_GETCONNECTOR, &c, "GETCONNECTOR"))
		return -1;
	c.count_modes = 0;
	c.modes_ptr = 0;
	c.encoders_ptr = 0;
	c.count_encoders = 0;
	c.props_ptr = (uint64_t)(uintptr_t)props_tmp;
	c.prop_values_ptr = (uint64_t)(uintptr_t)vals_tmp;
	c.count_props = MAX_PROPS;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_GETCONNECTOR, &c, "GETCONNECTOR(2)"))
		return -1;
	if (c.count_props > MAX_PROPS)
		return -1;
	*type = c.connector_type;
	*type_id = c.connector_type_id;
	*conn_state = c.connection;
	*encoder_id = c.encoder_id;
	*n_props = c.count_props;
	memcpy(props, props_tmp, sizeof(uint32_t) * *n_props);
	memcpy(vals, vals_tmp, sizeof(uint64_t) * *n_props);
	return 0;
}

/* EDID を blob プロパティ経由で読む */
static int get_edid(int fd, const uint32_t *props, const uint64_t *vals, uint32_t n,
		    unsigned char *buf, size_t bufsz)
{
	struct drm_mode_get_blob b;
	uint64_t blob_id = 0;

	if (props_lookup(fd, props, vals, n, "EDID", &blob_id, NULL) < 0 || !blob_id)
		return -1;
	memset(&b, 0, sizeof(b));
	b.blob_id = (uint32_t)blob_id;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_GETPROPBLOB, &b, "GETPROPBLOB(size)"))
		return -1;
	if (b.length == 0 || b.length > bufsz)
		return -1;
	b.data = (uint64_t)(uintptr_t)buf;
	if (ioctl_ret(fd, DRM_IOCTL_MODE_GETPROPBLOB, &b, "GETPROPBLOB(data)"))
		return -1;
	return (int)b.length;
}

/*
 * EDID の Monitor Range Limits(タグ 0xFD)から垂直レンジを取る。
 * ベースブロックの 54 バイト目から 18 バイト×4 のディスクリプタが並ぶ。
 */
static int edid_range(const unsigned char *e, int len, int *min_hz, int *max_hz)
{
	int i;

	if (len < 128)
		return -1;
	for (i = 0; i < 4; i++) {
		const unsigned char *d = e + 54 + i * 18;

		if (d[0] || d[1] || d[2] || d[3] != 0xfd)
			continue;
		*min_hz = d[5];
		*max_hz = d[6];
		return 0;
	}
	return -1;
}

static int cmp_double(const void *a, const void *b)
{
	double x = *(const double *)a, y = *(const double *)b;

	return (x > y) - (x < y);
}

/*
 * vblank の周期を実測する。CRTC インデックス(= GETRESOURCES の crtcs 配列の順番)を
 * 指定する。戻り値はサンプル数、interval_us に周期[us]、secs は実測秒数。
 */
static int measure_vblank(int fd, int crtc_index, double secs,
			  double *interval_us, int max_n)
{
	union drm_wait_vblank vb;
	long long prev = 0;
	double end;
	int n = 0;

	end = now_mono() + secs;
	while (now_mono() < end && n < max_n) {
		long long cur;

		memset(&vb, 0, sizeof(vb));
		vb.request.type = DRM_VBLANK_RELATIVE |
				  ((uint32_t)crtc_index << DRM_VBLANK_HIGH_CRTC_SHIFT);
		vb.request.sequence = 1; /* 次の vblank まで待つ */
		if (ioctl(fd, DRM_IOCTL_WAIT_VBLANK, &vb) < 0) {
			if (n == 0)
				return -1;
			break;
		}
		cur = (long long)vb.reply.tval_sec * 1000000LL + vb.reply.tval_usec;
		if (prev)
			interval_us[n++] = (double)(cur - prev);
		prev = cur;
	}
	return n;
}

/* ------------------------------------------------------------------ main */

static void usage(const char *argv0)
{
	printf("usage: %s [-d /dev/dri/cardN] [-s seconds] [-n] [-v]\n"
	       "  -d  DRM device (default: first of /dev/dri/card0..9 that opens)\n"
	       "  -s  vblank measurement duration in seconds (default 4)\n"
	       "  -n  skip the vblank measurement (capability check only)\n"
	       "  -v  dump all connector properties (debugging)\n",
	       argv0);
}

static void print_hints(void)
{
	printf("    how to enable VRR:\n"
	       "      KDE Plasma : System Settings > Display > Adaptive Sync (per screen)\n"
	       "      GNOME      : gsettings set org.gnome.mutter experimental-features \"['variable-refresh-rate']\"\n"
	       "      sway/wlroots: output <name> adaptive_sync on\n"
	       "      niri       : output \"<name>\" { variable-refresh-rate }\n"
	       "      Hyprland   : misc:vrr = 1 (or 2)\n");
}

int main(int argc, char **argv)
{
	const char *dev = NULL;
	double seconds = 4.0;
	int do_measure = 1;
	int verbose = 0;
	int fd = -1, opt;
	char devbuf[64];
	struct utsname uts;

	while ((opt = getopt(argc, argv, "d:s:nvh")) != -1) {
		switch (opt) {
		case 'd': dev = optarg; break;
		case 's': seconds = atof(optarg); break;
		case 'n': do_measure = 0; break;
		case 'v': verbose = 1; break;
		default: usage(argv[0]); return opt == 'h' ? 0 : 2;
		}
	}

	if (!dev) {
		int i;
		char firstdev[64] = "";
		int firsterr = 0;

		for (i = 0; i < 10; i++) {
			snprintf(devbuf, sizeof(devbuf), "/dev/dri/card%d", i);
			fd = open(devbuf, O_RDWR | O_CLOEXEC);
			if (fd >= 0) {
				dev = devbuf;
				break;
			}
			if (i == 0) {
				snprintf(firstdev, sizeof(firstdev), "%s", devbuf);
				firsterr = errno;
			}
		}
		if (fd < 0) {
			fprintf(stderr,
				"error: %s: %s (and card1..9 did not open either)\n"
				"  - not in a local graphical session? try sudo\n"
				"  - in a container? /dev/dri must be passed through "
				"(podman --device /dev/dri:/dev/dri) and the process must run "
				"as a user whose uid/gid are mapped into the container "
				"(container-root usually cannot open card0).\n",
				firstdev, strerror(firsterr));
			return 1;
		}
	} else {
		fd = open(dev, O_RDWR | O_CLOEXEC);
		if (fd < 0) {
			perror(dev);
			return 1;
		}
	}

	if (uname(&uts) == 0)
		printf("kernel %s  device %s  uid %d\n", uts.release, dev, (int)geteuid());
	else
		printf("device %s  uid %d\n", dev, (int)geteuid());

	{
		/* /sys/class/drm/<cardN>/device/driver からドライバ名を出す */
		char path[128], link[256];
		const char *base = strrchr(dev, '/');
		ssize_t l;

		snprintf(path, sizeof(path), "/sys/class/drm/%s/device/driver",
			 base ? base + 1 : "card0");
		l = readlink(path, link, sizeof(link) - 1);
		if (l > 0) {
			const char *nm;
			char *slash;

			link[l] = '\0';
			slash = strrchr(link, '/');
			nm = slash ? slash + 1 : link;
			printf("driver %s\n", nm);
		}
	}

	{
		/* CRTC_ID / FB_ID などの atomic プロパティはこの cap を立てないと
		 * GETCONNECTOR の一覧に出てこない(出ないとコネクタ→CRTC が引けない)。
		 * 失敗しても致命ではないので、その場合は encoder 経由にフォールバック。 */
		struct drm_set_client_cap cap;

		cap.capability = 3; /* DRM_CLIENT_CAP_ATOMIC */
		cap.value = 1;
		if (ioctl(fd, DRM_IOCTL_SET_CLIENT_CAP, &cap) < 0 && verbose)
			fprintf(stderr, "  note: SET_CLIENT_CAP(ATOMIC) failed: %s\n",
				strerror(errno));
	}

	{
		uint32_t crtcs[MAX_CRTCS] = { 0 }, conns[MAX_CONNECTORS] = { 0 };
		uint32_t n_crtcs = 0, n_conns = 0, i;
		int capable_count = 0, enabled_count = 0;

		if (get_resources(fd, crtcs, &n_crtcs, conns, &n_conns) < 0)
			return 1;

		for (i = 0; i < n_conns; i++) {
			uint32_t type, type_id, state, enc_id, n_props = 0;
			uint32_t props[MAX_PROPS] = { 0 };
			uint64_t vals[MAX_PROPS] = { 0 };
			uint64_t capable = 0, crtc_id = 0;
			uint64_t vrr_enabled = 0;
			int have_enabled = 0;
			unsigned char edid[1024];
			int edid_len, min_hz = 0, max_hz = 0, crtc_idx = -1;
			char cname[64];

			if (get_connector(fd, conns[i], &type, &type_id, &state, &enc_id,
					  props, vals, &n_props) < 0)
				continue;

			snprintf(cname, sizeof(cname), "%s-%u", conn_type_name(type), type_id);
			printf("\n[connector %u] %s  %s\n", conns[i], cname,
			       state == 1 ? "connected" : "disconnected");

			if (props_lookup(fd, props, vals, n_props, "vrr_capable", &capable, NULL) < 0) {
				printf("  vrr_capable : property not present "
				       "(driver/kernel does not support VRR here)\n");
				continue;
			}
			printf("  vrr_capable : %s\n", capable ? "yes" : "no");

			edid_len = get_edid(fd, props, vals, n_props, edid, sizeof(edid));
			if (edid_len > 0 && edid_range(edid, edid_len, &min_hz, &max_hz) == 0)
				printf("  EDID range  : %d-%d Hz (Monitor Range Limits)\n",
				       min_hz, max_hz);
			else
				printf("  EDID range  : unknown\n");

			if (state != 1)
				continue;
			if (!capable) {
				printf("  => not VRR capable\n");
				continue;
			}
			capable_count++;

			/* コネクタが載っている CRTC。atomic ドライバでは encoder_id が 0 の
			 * ことがあるので、まず connector の CRTC_ID プロパティを見る
			 * (無ければ従来の encoder 経由)。 */
			if (props_lookup(fd, props, vals, n_props, "CRTC_ID", &crtc_id, NULL) < 0 &&
			    enc_id) {
				struct drm_mode_get_encoder e;

				memset(&e, 0, sizeof(e));
				e.encoder_id = enc_id;
				if (ioctl(fd, DRM_IOCTL_MODE_GETENCODER, &e) == 0)
					crtc_id = e.crtc_id;
			}
			if (verbose) {
				uint32_t k;

				for (k = 0; k < n_props; k++) {
					char nm[64] = "";

					get_prop_name(fd, props[k], nm, sizeof(nm), NULL);
					printf("    prop %-24s = %llu\n", nm,
					       (unsigned long long)vals[k]);
				}
			}

			if (crtc_id) {
				uint32_t cprops[MAX_PROPS] = { 0 };
				uint64_t cvals[MAX_PROPS] = { 0 };
				uint32_t cn = 0;

				if (obj_get_props(fd, crtc_id, DRM_MODE_OBJECT_CRTC,
						  cprops, cvals, &cn) == 0 &&
				    props_lookup(fd, cprops, cvals, cn, "VRR_ENABLED",
						 &vrr_enabled, NULL) == 0) {
					have_enabled = 1;
					printf("  VRR_ENABLED : %s (crtc %u)\n",
					       vrr_enabled ? "yes" : "no", (unsigned)crtc_id);
					if (vrr_enabled)
						enabled_count++;
				} else {
					printf("  VRR_ENABLED : property not present\n");
				}
			} else {
				printf("  VRR_ENABLED : connector is not on any CRTC "
				       "(screen off / not active)\n");
			}

			if (crtc_id) {
				uint32_t k;

				for (k = 0; k < n_crtcs; k++)
					if (crtcs[k] == crtc_id)
						crtc_idx = (int)k;
			}

			if (!crtc_id || crtc_idx < 0 || !do_measure) {
				if (!do_measure)
					printf("  measurement : skipped (-n)\n");
				continue;
			}

			{
				static double iv[8192];
				int n = measure_vblank(fd, crtc_idx, seconds, iv, 8192);

				if (n < 2) {
					printf("  measurement : failed "
					       "(WAIT_VBLANK returned %d samples)\n", n);
					continue;
				}
				qsort(iv, n, sizeof(iv[0]), cmp_double);
				{
					double min = iv[0], max = iv[n - 1], p50 = iv[n / 2];
					double base_us = max_hz > 0 ? 1e6 / (double)max_hz : p50;

					printf("  measurement : n=%d  period min=%.2f p50=%.2f "
					       "max=%.2f ms  (baseline %.2f ms / %.1f Hz)\n",
					       n, min / 1000, p50 / 1000, max / 1000,
					       base_us / 1000, 1e6 / base_us);
					/*
					 * VRR 無効なら周期はハードウェアの固定タイミング由来で
					 * ぶれない(実測で ±0.1%)。基準より 10% 以上長い周期が
					 * 出たら、パネルが内容に追従して遅くリフレッシュした証拠。
					 * (逆に基準より短い周期はドライバの VRR flip 集計なので無視)
					 */
					if (max > base_us * 1.10) {
						printf("  => adaptive sync IS RUNNING: refresh went "
						       "as low as %.1f Hz (baseline %.1f Hz)\n",
						       1e6 / max, 1e6 / base_us);
					} else if (vrr_enabled) {
						printf("  => VRR_ENABLED=yes but the refresh never left "
						       "the baseline during the measurement.\n"
						       "     The screen probably never went low-fps "
						       "during it; re-run while (mostly) idle.\n");
					} else {
						printf("  => refresh is pinned to the baseline and "
						       "VRR is %s.\n",
						       have_enabled ? "disabled" :
						       "not switchable here");
						print_hints();
					}
				}
			}
		}

		printf("\nsummary: %d connected VRR-capable connector(s), %d with VRR enabled\n",
		       capable_count, enabled_count);
		if (capable_count && !enabled_count) {
			printf("VRR is supported but not enabled - enable it in your "
			       "desktop/compositor and re-run.\n");
			print_hints();
		} else if (capable_count && enabled_count) {
			printf("see per-connector '=> adaptive sync IS running' above for "
			       "whether it actually modulates the panel.\n");
		} else if (!capable_count) {
			printf("no VRR-capable connector found (panel/driver/VBT may not "
			       "support adaptive sync).\n");
		}
	}

	close(fd);
	return 0;
}
