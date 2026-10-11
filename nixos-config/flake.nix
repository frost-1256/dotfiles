{
  description = "haru's NixOS and Home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nix-hazkey.url = "github:aster-void/nix-hazkey";
    nix-hazkey.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    run-vm.url = "github:frost-1256/run-vm";
    discord-rpc.url = "github:frost-1256/discord-rpc";
    discord-rpc.inputs.nixpkgs.follows = "nixpkgs";
    nixos-vrchat.url = "github:frost-1256/nixos-vrchat";
    nixos-vrchat.inputs.nixpkgs.follows = "nixpkgs";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    omp.url = "github:can1357/oh-my-pi";
    gaze.url = "github:GunduLabs/gaze";
    # Rust 製のネイティブ Discord クライアント (egui/wgpu)。
    # 上流 flake は packages のみ (nixosModules / homeManagerModules は無い) なので
    # home/serein で home.packages に積むだけになる。
#    serein.url = "github:ViceVerse-cz/Serein";
#    serein.inputs.nixpkgs.follows = "nixpkgs";
    gaze.inputs.nixpkgs.follows = "nixpkgs";
    # Droidspaces (Android 上の LXC ランタイム) 用 NixOS モジュール。
    # lxc-aarch64 からのみ参照する。follows は付けない (公式手順通り)。
    droidspaces.url = "github:ravindu644/Droidspaces-OSS";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      nix-hazkey,
      noctalia,
      niri,
      run-vm,
      nixos-vrchat,
      chaotic,
      gaze,
      omp,
      serein,
      droidspaces,
      ...
    }@inputs:
    let
      mkHomeModules = username: [
        noctalia.homeModules.default
        nix-hazkey.homeModules.hazkey
        nixvim.homeModules.nixvim
        omp.homeManagerModules.default
        ./users/${username}/home.nix
      ];

      mkPortableHomeModules = username: [
        nixvim.homeModules.nixvim
        ./users/${username}/home-portable.nix
      ];

      # standalone HM (homeConfigurations.spring) 用。
      # NixOS では nixosModules.niri が homeModules.config を sharedModules に
      # 自動注入するが、standalone にはその経路が無いので programs.niri が未定義になる。
      # よって niri の home-module を明示的に足す（NixOS 側 mkHomeModules には入れない）。
      mkStandaloneHomeModules =
        username:
        mkHomeModules username
        ++ [
          niri.homeModules.niri
        ];

      mkHomeSpecialArgs =
        username:
        inputs
        // {
          inherit inputs;
          inherit username;
        };

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config = import ./nixpkgs-config.nix;
          # standalone HM にも niri overlay を適用し、home/niri が参照する
          # niri-unstable / xwayland-satellite-unstable 等を解決する
          # (NixOS では modules/niri.nix が同じ overlay を当てている)。
          overlays = [
            (import ./overlays/niri-compat.nix)
            niri.overlays.niri
          ];
        };

      mkHomeConfiguration =
        {
          username,
          system,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = mkHomeSpecialArgs username;
          modules = mkStandaloneHomeModules username;
        };

      mkPortableHomeConfiguration =
        {
          username,
          system,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = mkHomeSpecialArgs username;
          modules = mkPortableHomeModules username;
        };
    in
    {
      nixosConfigurations = {
        spring-t14-gen6 =
          let
            username = "spring";
            specialArgs = inputs // {
              inherit username;
            };
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            system = "x86_64-linux";

            modules = [
              noctalia.nixosModules.default

              niri.nixosModules.niri
              run-vm.nixosModules.default
              nixos-vrchat.nixosModules.default
              chaotic.nixosModules.default
              gaze.nixosModules.default

              {
                _module.args.inputs = inputs;
              }

              ./hosts/spring-t14-gen6

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.extraSpecialArgs = mkHomeSpecialArgs username;
                home-manager.users.${username}.imports = mkHomeModules username;
              }

              {
                programs.noctalia = {
                  enable = true;
                  recommendedServices.enable = true;
                };
              }
            ];
          };

        spring-desktop =
          let
            username = "spring";
            specialArgs = inputs // {
              inherit username;
            };
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            system = "x86_64-linux";

            modules = [
              noctalia.nixosModules.default

              niri.nixosModules.niri
              run-vm.nixosModules.default
              nixos-vrchat.nixosModules.default
              chaotic.nixosModules.default
              gaze.nixosModules.default

              {
                _module.args.inputs = inputs;
              }

              ./hosts/spring-t14-gen6

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.extraSpecialArgs = mkHomeSpecialArgs username;
                home-manager.users.${username}.imports = mkHomeModules username;
              }

              {
                programs.noctalia = {
                  enable = true;
                  recommendedServices.enable = true;
                };
              }
            ];
          };


        # aarch64 NixOS LXC コンテナ用。既存ホストとは独立した最小構成 +
        # portable home (nvim + shell + core)。デスクトップ系 flake モジュール
        # (noctalia / niri / gaze 等) はコンテナに不要なため付けない。
        lxc-aarch64 =
          let
            username = "spring";
            specialArgs = inputs // {
              inherit username;
            };
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            system = "aarch64-linux";

            modules = [
              # Droidspaces 公式手順 (https://www.droidspaces.org/docs/nix-nixos.html)。
              # lxc-container.nix の import と tarball ビルド
              # (system.build.tarball) を提供する。
              droidspaces.nixosModules.working-droidspaces-rootfs-minimal
              ./hosts/lxc-aarch64

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.extraSpecialArgs = mkHomeSpecialArgs username;
                home-manager.users.${username}.imports = mkPortableHomeModules username;
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
