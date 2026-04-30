{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    pure-prompt
    zsh-completions
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm"
    "/usr/local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";

    completionInit = ''
      autoload -Uz compinit
      zcompdump=${config.home.homeDirectory}/.zcompdump

      if [[ -f $zcompdump ]]; then
        compinit -C -d $zcompdump
      else
        compinit -d $zcompdump
      fi
    '';

    history = {
      path = "${config.home.homeDirectory}/.histfile";
      size = 1000;
      save = 1000;
      ignoreSpace = false;
    };

    shellAliases = {
      nix-gc = "sudo nix-collect-garbage -d && sudo nixos-rebuild switch";
      ":q" = "exit";
      vim = "nvim";
      vi = "nvim";
      kernel-build = "sudo systemd-nspawn -D /var/lib/machines/kernel-build --network-veth --resolv-conf=auto /bin/bash";
      ubuntu-bootstrap = "sudo ubuntu-nspawn-bootstrap noble /var/lib/machines/ubuntu";
      ubuntu-network-init = "sudo ubuntu-nspawn-configure-network /var/lib/machines/ubuntu";
      ubuntu-container = "sudo systemd-nspawn -M ubuntu -D /var/lib/machines/ubuntu --boot --network-veth --resolv-conf=auto";
      ubuntu-shell = "sudo systemd-nspawn -M ubuntu -D /var/lib/machines/ubuntu --network-veth --resolv-conf=auto /bin/bash";
      ubuntu-machine-start = "sudo ubuntu-nspawn-configure-network /var/lib/machines/ubuntu && sudo systemctl start systemd-nspawn@ubuntu";
      ubuntu-machine-stop = "sudo systemctl stop systemd-nspawn@ubuntu";
    };

    setOptions = [ "NO_NOMATCH" ];

    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        typeset -U path
      '')

      (lib.mkOrder 1000 ''
        function ubuntu-machine-shell {
          local user="''${1:-root}"
          sudo machinectl shell "''${user}@ubuntu"
        }

        bindkey "^[OH" beginning-of-line
        bindkey "^[OF" end-of-line
        bindkey "^[[3~" delete-char

        autoload -Uz promptinit
        promptinit
        prompt pure
      '')
    ];
  };
}
