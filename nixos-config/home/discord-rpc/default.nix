{
  inputs,
  ...
}: {
  imports = [
    inputs.discord-rpc.nixosModules.default
  ];

  services.rpc-server.enable = true;
}
