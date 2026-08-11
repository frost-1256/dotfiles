{
  config,
  ...
}: {
  users.users.spring.extraGroups = ["podman"];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    autoPrune.enable = true;
    defaultNetwork.dnsname.enable = true;
  };
}