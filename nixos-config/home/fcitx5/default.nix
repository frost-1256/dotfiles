{
  config,
  pkgs,
  ...
} @ args: let
  inherit (pkgs.stdenv) system;
  nix-hazkey = args.nix-hazkey;
in {
  services.hazkey = {
    enable = true;
    server.package = nix-hazkey.packages.${system}.hazkey-server.override {
      enableVulkan = true;
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      qt6Packages.fcitx5-configtool
    ];
  };
}
