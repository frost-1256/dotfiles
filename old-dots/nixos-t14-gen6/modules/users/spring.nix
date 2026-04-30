{ pkgs, ... }: {
  users.users.spring = {
    isNormalUser = true;
    description = "spring";
    extraGroups = [ "networkmanager" "wheel" "wireshark" "docker" "input" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    ];
  };
}
