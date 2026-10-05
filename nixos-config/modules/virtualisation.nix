{
  pkgs,
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
}
