{
  ccusage,
  llm-agents,
  nix-claude-code,
  pkgs,
  ...
}: {
  imports = [
    ../../home/nvim
    ../../home/shell
    ../../home/core.nix
  ];
  home.packages = with pkgs; [
    github-cli
    nix-search-cli
    nix-claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default
    ccusage.packages.${pkgs.stdenv.hostPlatform.system}.default
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccstatusline
  ];
  home.file.".claude/settings.json" = {
    force = true;
    text = builtins.toJSON {
      effortLevel = "medium";
      theme = "auto";
      statusLine = {
        type = "command";
        command = "ccstatusline";
        padding = 0;
        refreshInterval = 10;
      };
    };
  };
  programs.gpg.enable = true;
  programs.git.settings = {
    user.name = "spring";
    user.email = "harusan@spring-server.com";
  };
}
