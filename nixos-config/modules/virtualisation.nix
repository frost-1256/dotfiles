{
  config,
  pkgs,
  lib,
  username,
  ...
}:
{
  users.users.${username}.extraGroups = [ "libvirtd" ];

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
    extraOptions = [
      "--timeout"
      "0"
    ];
  };

  # libvirtd (約2.1秒) を boot の critical path から外す。
  # libvirtd.socket 群は残るため、初回接続時 (virt-manager/virsh/run-vm) に
  # 起動する (socket activation)。-2 秒。
  # 注意: libvirt-guests も外すため、host 電源off時に起動中 VM の
  # 自動 suspend は効かなくなる (VM 起動中の電源offは避けること)。
  systemd.services.libvirtd.wantedBy = lib.mkForce [ ];
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [ ];

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    spice-gtk
    spice-protocol
    virtio-win
    looking-glass-client
    virt-viewer
  ];

  # 注意: vfio_virqfd は kernel 6.x で vfio 本体に統合済みでモジュールが無い。
  # 書くと systemd-modules-load が毎回
  # "Failed to find module 'vfio_virqfd'" を出すので入れない。
  boot.kernelModules = [
    "kvm-intel"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  services.spice-webdavd.enable = true;

  # vm-curator 等の FHS 前提ツール用に OVMF の定番パスを生やす
  # (NixOS には /usr/share/OVMF が無いので、未対応だと
  # "OVMF_CODE.fd not found" で UEFI 起動 VM が作れない)。実体は libvirtd と
  # 同じ QEMU パッケージの edk2。x86_64 の varstore テンプレートは i386 と
  # 共通の edk2-i386-vars.fd (60-edk2-x86_64.json の nvram-template 参照)。
  #
  # CODE は read-only で使うため symlink のまま (実体も 444)。
  # VARS は 0644 の実体コピーにしている。ツールは起動スクリプト内で
  # `cp $VARS_TEMPLATE $VM_DIR/OVMF_VARS.fd` として VM 毎に writable な
  # コピーを作るが、GNU cp は新ファイルに source の mode を付けるため、
  # テンプレートが 444 だと copy も 444 になり qemu の pflash 書き込みが
  # "Permission denied" で落ちる (NixOS 固有の罠。通常ディストロは 644)。
  # symlink だと同じ理由で 444 が伝播するので C (実体コピー) を使う。
  # QEMU 更新で store パスが変わっても VARS は古いコピーのままなので、
  # reboot 後に "Permission denied" が出たら VARS.fd を rm して tmpfiles を
  # 起動し直す (C は既存ファイルを上書きしないため)。
  systemd.tmpfiles.rules =
    let
      qemuPkg = config.virtualisation.libvirtd.qemu.package;
    in
    [
      "d /usr/share/OVMF 0755 root root -"
      "L+ /usr/share/OVMF/OVMF_CODE.fd - - - - ${qemuPkg}/share/qemu/edk2-x86_64-code.fd"
      "C /usr/share/OVMF/OVMF_VARS.fd 0644 root root - ${qemuPkg}/share/qemu/edk2-i386-vars.fd"
    ];
}
