{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libei,
  libxkbcommon,
}:
# niri 用の RemoteDesktop 専用 portal backend (ConnectToEIS 対応)。
# EIS で受けた入力を zwlr_virtual_pointer / zwp_virtual_keyboard で niri に流す。
# 許可ダイアログは無い (session bus 上の任意クライアントが入力注入できる)。
rustPlatform.buildRustPackage {
  pname = "virtinput-portal";
  version = "0.1.0-unstable-2026-10-14";

  src = fetchFromGitHub {
    owner = "NailFec";
    repo = "virtinput-portal";
    rev = "e672a3f1e3f2c94852fe7fe6f7b2d77a718f9306";
    hash = "sha256-LsxIxH5x81Lhwjv03uftFAf8P9e73oUqtjAry7iD7S0=";
  };

  # キーボードを zwp_virtual_keyboard ではなく uinput に流す自前パッチ。
  # niri は virtual keyboard の入力をフォーカス中クライアントへ直送するため、
  # キーバインド (Mod 系) と IME (fcitx5) を素通りしてしまう (2026-11-09 実測)。
  # uinput なら libinput 経由の物理キーボード扱いになる。/dev/uinput が
  # 開けなければ従来の virtual keyboard にフォールバックする。
  # restrict-callers: impl portal は session bus 上の誰でも直接呼べ app_id も
  # 自己申告なので、CreateSession の呼び出し元が org.freedesktop.portal.Desktop
  # の現オーナーであること・app_id が VIRTINPUT_ALLOWED_APP_IDS (カンマ区切り、
  # 未設定なら全許可) に含まれることを検査し、以降の呼び出しは作成元と同じ
  # 送信者に限る。
  patches = [
    ./patches/virtinput-portal-uinput-keyboard.patch
    ./patches/virtinput-portal-restrict-callers.patch
  ];

  cargoHash = "sha256-hTGB/cs1cH5EgGdkqIip4H87iFZ16wlAClrmMzYWcFg=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libei
    libxkbcommon
  ];

  # 上流 data/ は ~/.local 配置前提なので、store パスに合わせて入れ直す。
  # systemd user unit は D-Bus activation (SystemdService=) 専用で WantedBy は付けない。
  postInstall = ''
    install -Dm644 data/virtinput.portal -t $out/share/xdg-desktop-portal/portals
    mkdir -p $out/share/dbus-1/services
    substitute data/org.freedesktop.impl.portal.desktop.virtinput.service \
      $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.virtinput.service \
      --replace-fail @BIN@ $out/bin/virtinput-portal
    install -Dm644 /dev/stdin $out/lib/systemd/user/virtinput-portal.service <<EOF
    [Unit]
    Description=RemoteDesktop portal backend for Wayland virtual input
    PartOf=graphical-session.target
    After=graphical-session.target

    [Service]
    Type=dbus
    BusName=org.freedesktop.impl.portal.desktop.virtinput
    ExecStart=$out/bin/virtinput-portal
    Restart=on-failure
    RestartSec=2
    Environment=RUST_LOG=info
    EOF
    rm -f $out/bin/smoke
  '';

  meta = {
    description = "RemoteDesktop portal backend that injects input through Wayland virtual devices";
    homepage = "https://github.com/NailFec/virtinput-portal";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "virtinput-portal";
  };
}
