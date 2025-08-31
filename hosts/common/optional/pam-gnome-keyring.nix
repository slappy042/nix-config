# PAM configuration for gnome-keyring automatic unlock
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Enable gnome-keyring service
  services.gnome.gnome-keyring.enable = true;

  # PAM configuration for automatic keyring unlock
  security.pam.services = {
    login.enableGnomeKeyring = true;
    sddm.enableGnomeKeyring = true;
    sddm-greeter.enableGnomeKeyring = true;
    sudo.enableGnomeKeyring = true;
  };

  # Install required packages
  environment.systemPackages = with pkgs; [
    gnome.gnome-keyring
    gnome.libgnome-keyring
    libsecret # For secret management
    seahorse # GUI for managing keyring
  ];

  # Enable SSH agent auth for sudo (optional but recommended)
  security.pam.sshAgentAuth.enable = true;

  # Set environment variables for keyring
  environment.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  };
}
