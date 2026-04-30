{ ... }: {
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "0001:0001:09b4e68d" ];
        settings = {
          main = {
            "leftshift+leftmeta+f23" = "f13";
          };
        };
      };
    };
  };
}
