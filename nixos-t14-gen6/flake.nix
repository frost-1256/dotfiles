{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };
  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs: {
    nixosConfigurations.spring-t14-gen6 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
	nixos-hardware.nixosModules.lenovo-thinkpad-t14-intel-gen6
      ];
    };
  };
}
