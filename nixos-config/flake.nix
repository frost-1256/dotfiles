{
  description = "haru's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nix-hazkey.url = "github:aster-void/nix-hazkey";
    nix-hazkey.inputs.nixpkgs.follows = "nixpkgs";
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    nix-claude-code.inputs.nixpkgs.follows = "nixpkgs";
    ccusage.url = "github:ryoppippi/ccusage";
    ccusage.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
    # push 前のローカル改良 (gpu.vendor / performanceMode) を使うため path 参照。
    # GitHub へ push 済みなら "github:frost-1256/nixos-vrchat" に戻してよい。
    nixos-vrchat.url = "path:/home/spring/nixos-vrchat";
    nixos-vrchat.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: let
    mkHomeModules = username: [
      inputs.nix-hazkey.homeModules.hazkey
      inputs.nixvim.homeModules.nixvim
      ./users/${username}/home.nix
    ];

    mkPortableHomeModules = username: [
      inputs.nixvim.homeModules.nixvim
      ./users/${username}/home-portable.nix
    ];

    mkHomeSpecialArgs = username: inputs // {inherit username;};

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [
          "electron-38.8.4"
        ];
      };

    mkHomeConfiguration = {
      username,
      system,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        extraSpecialArgs = mkHomeSpecialArgs username;
        modules = mkHomeModules username;
      };

    mkPortableHomeConfiguration = {
      username,
      system,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        extraSpecialArgs = mkHomeSpecialArgs username;
        modules = mkPortableHomeModules username;
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

            inputs.nixos-vrchat.nixosModules.default

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

      "spring@x86_64-linux" = mkPortableHomeConfiguration {
        username = "spring";
        system = "x86_64-linux";
      };

      "spring@aarch64-linux" = mkPortableHomeConfiguration {
        username = "spring";
        system = "aarch64-linux";
      };

      "spring@aarch64-darwin" = mkPortableHomeConfiguration {
        username = "spring";
        system = "aarch64-darwin";
      };
    };
  };
}
