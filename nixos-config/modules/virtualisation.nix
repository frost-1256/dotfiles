{
  pkgs,
  config,
  lib,
  ...
}: {
  users.users.spring.extraGroups = ["libvirtd"];

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
    extraOptions = [ "--timeout" "0" ];
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    spice-gtk
    spice-protocol
    virtio-win
    looking-glass-client
    virt-viewer
  ];

  boot.kernelModules = ["kvm-intel" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd"];
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  services.spice-webdavd.enable = true;
}