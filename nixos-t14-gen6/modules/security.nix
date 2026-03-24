{ ... }: {
   security.rtkit.enable = true;
   security.pam.services.login.enableGnomeKeyring = true;
}
