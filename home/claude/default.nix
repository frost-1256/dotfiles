{
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
    inputs.nix-claude-code.packages.${system}.default
    inputs.ccusage.packages.${system}.default
    inputs.llm-agents.packages.${system}.ccstatusline
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
}
