{ ... }: {
   services.logind.settings.Login.HandlePowerKey = "suspend";
   services.logind.settings.Login.HandleLidSwitch = "suspend";
}
