{ ... }: {
  networking.hostName = "spring-t14-gen6"; # Define your hostname.
  networking.networkmanager.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall.enable = true;
}
