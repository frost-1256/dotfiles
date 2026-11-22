{
  description = "haru's NixOS and Home-manager configuration";

  # インストール時 (ISO 側 nix) のバイナリキャッシュ。
  # modules/system.nix の nix.settings は完成系の /etc/nix/nix.conf にしか効かず、
  # nixos-install 実行中の ISO 側には効かないため、chaotic カーネル等が
  # ソースビルドになる。これで nixos-install --accept-flake-config --flake .#<host>
  # とすれば ISO 側でも代替キャッシュが使われる (通常の rebuild には無影響)。
  # nixConfig に書けるのは extra-* 系のみ。鍵は下の実測値と同一に保つこと。
  nixConfig = {
    extra-substituters = [
      "https://nyx-cache.chaotic.cx/"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
      "https://nixos-nothing-spacewar.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nixos-nothing-spacewar.cachix.org-1:TWmfQAaPB47M0zWUX6m2YgjKKu+WJYqwFtt9nR9pZDU="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    # 日本語入力 (fcitx5 アドオン)。home/fcitx5 で使う
    sweet-ime.url = "github:frost-1256/sweet-ime";
    sweet-ime.inputs.nixpkgs.follows = "nixpkgs";
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    nix-claude-code.inputs.nixpkgs.follows = "nixpkgs";
    ccusage.url = "github:ryoppippi/ccusage";
    ccusage.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    omp.url = "github:can1357/oh-my-pi";
    gaze.url = "github:GunduLabs/gaze";
    gaze.inputs.nixpkgs.follows = "nixpkgs";
    # VRChat (Quest + WiVRn / xrizer) と Unity/ALCOM 制作環境の NixOS モジュール (ユーザー自身のリポジトリ)。
    # spring-b550m-pro4 の host から import する (t14 では使わない)。
    nixos-vrchat.url = "github:frost-1256/nixos-vrchat";
    nixos-vrchat.inputs.nixpkgs.follows = "nixpkgs";
    # 未知のバイナリの不足ライブラリを nix-index で調べて取ってきて実行する (nix-alien)。
    # 構築済み nix-index DB (nix-index-database) を同梱。modules/nix-ld.nix (両デスクトップ) で使う
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-alien.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    # Droidspaces (Android 上の LXC ランタイム) 用 NixOS モジュール。
    # lxc-aarch64 からのみ参照する。follows は付けない (公式手順通り)。
    droidspaces.url = "github:ravindu644/Droidspaces-OSS";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      noctalia,
      niri,
      chaotic,
      gaze,
      omp,
      droidspaces,
      ...
    }@inputs:
    let
      username = "spring";

      # NixOS / HM 両方のモジュール引数。inputs を展開したもの (`{ niri, ... }`) と
      # まとめたもの (`{ inputs, ... }`) の両方で取れるようにする。
      specialArgs = inputs // {
        inherit inputs username;
      };

      mkHomeModules = username: [
        noctalia.homeModules.default
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
      mkStandaloneHomeModules = username: mkHomeModules username ++ [ niri.homeModules.niri ];

      # NixOS に home-manager を組み込むモジュール
      mkHomeManagerModule = homeModules: {
        imports = [ home-manager.nixosModules.home-manager ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = specialArgs;
          users.${username}.imports = homeModules;
        };
      };

      # デスクトップホスト (Niri + Noctalia + HM フル構成)。違いは hosts/<host> 側に書く。
      mkDesktopHost =
        host:
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = [
            noctalia.nixosModules.default
            niri.nixosModules.niri
            chaotic.nixosModules.default
            gaze.nixosModules.default
            ./hosts/${host}
            (mkHomeManagerModule (mkHomeModules username))
            {
              programs.noctalia = {
                enable = true;
                recommendedServices.enable = true;
              };
            }
          ];
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
        modules: system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = specialArgs;
          inherit modules;
        };
      mkPortableHomeConfiguration = mkHomeConfiguration (mkPortableHomeModules username);
    in
    {
      nixosConfigurations = {
        spring-t14-gen6 = mkDesktopHost "spring-t14-gen6";
        spring-b550m-pro4 = mkDesktopHost "spring-b550m-pro4";

        # aarch64 NixOS LXC コンテナ用。既存ホストとは独立した最小構成 +
        # portable home (nvim + shell + core)。デスクトップ系 flake モジュール
        # (noctalia / niri / gaze 等) はコンテナに不要なため付けない。
        lxc-aarch64 = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "aarch64-linux";
          modules = [
            # Droidspaces 公式手順 (https://www.droidspaces.org/docs/nix-nixos.html)。
            # lxc-container.nix の import と tarball ビルド
            # (system.build.tarball) を提供する。
            droidspaces.nixosModules.working-droidspaces-rootfs-minimal
            ./hosts/lxc-aarch64
            (mkHomeManagerModule (mkPortableHomeModules username))
          ];
        };
      };

      homeConfigurations = {
        ${username} = mkHomeConfiguration (mkStandaloneHomeModules username) "x86_64-linux";
        "${username}@x86_64-linux" = mkPortableHomeConfiguration "x86_64-linux";
        "${username}@aarch64-linux" = mkPortableHomeConfiguration "aarch64-linux";
        "${username}@aarch64-darwin" = mkPortableHomeConfiguration "aarch64-darwin";
      };
    };
}
