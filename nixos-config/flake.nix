{
  description = "haru's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    mkHomeModules = username: [
      inputs.nixvim.homeModules.nixvim
      ./users/${username}/home.nix
    ];

    mkHomeSpecialArgs = username: inputs // {inherit username;};

    mkHomeConfiguration = {
      username,
      system,
    }: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = mkHomeSpecialArgs username;
        modules = mkHomeModules username;
      };
  in {
    nixosConfigurations = {
      spring-t14-gen6 = let
        username = "spring";
        specialArgs = {inherit username;};
      in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";

          modules = [
            ./hosts/spring-t14-gen6
            ./users/${username}/nixos.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = mkHomeSpecialArgs username;
              home-manager.users.${username}.imports = mkHomeModules username;
            }
          ];
        };
    };

    homeConfigurations = {
      spring = mkHomeConfiguration {
        username = "spring";
        system = "x86_64-linux";
      };
    };
  };
}
