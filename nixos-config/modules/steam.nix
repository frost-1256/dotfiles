{pkgs, ...}: {
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    extraPackages = with pkgs; [
      libkrb5
      keyutils
    ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
    ];
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope
  ];
}
