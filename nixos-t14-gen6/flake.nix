{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Home Manager を追加
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs: {
    nixosConfigurations.spring-t14-gen6 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        # <home-manager/nixos> の代わりにこれを使います
        home-manager.nixosModules.home-manager
        
        {
          nixpkgs.overlays = [
            (final: prev: {
              wivrn = nixpkgs-unstable.legacyPackages.${prev.system}.wivrn;
            })
          ];
        }
      ];
    };
  };
}
