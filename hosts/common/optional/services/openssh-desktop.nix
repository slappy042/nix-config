# GPG agent configuration for desktop hosts.
# Provides SSH key management via gpg-agent with PAM integration for passphrase
# unlocking at login. Import this on any host with hasDesktop = true.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;

    settings = {
      default-cache-ttl = 60480000; # 1 week
      default-cache-ttl-ssh = 60480000;
      max-cache-ttl = 120960000; # 2 weeks
      max-cache-ttl-ssh = 120960000;
      allow-loopback-pinentry = "";
      allow-preset-passphrase = "";
    };
  };

  # Install GPG and related tools
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
    # YubiKey support (commented out - uncomment if you have a YubiKey)
    # yubikey-personalization
    # yubikey-manager
    # pcsclite
    # pcsctools
  ];

  # Enable smartcard daemon for YubiKey support (commented out - uncomment if you have a YubiKey)
  # services.pcscd.enable = true;

  # Configure udev rules for YubiKey access (commented out - uncomment if you have a YubiKey)
  # services.udev.packages = with pkgs; [
  #   yubikey-personalization
  #   yubikey-manager
  # ];

  # Unlock GPG keys (and by extension SSH keys) at login and re-lock on sudo
  security.pam.services = {
    login.gnupg = {
      enable = true;
      noAutostart = true;
      storeOnly = false;
    };
    sudo.gnupg = {
      enable = true;
      noAutostart = true;
      storeOnly = false;
    };
    sddm.gnupg = lib.mkIf config.services.displayManager.sddm.enable {
      enable = true;
      noAutostart = true;
      storeOnly = false;
    };
    gdm.gnupg = lib.mkIf config.services.displayManager.gdm.enable {
      enable = true;
      noAutostart = true;
      storeOnly = false;
    };
  };

  # Point SSH_AUTH_SOCK at gpg-agent's SSH socket so pam_gnupg-loaded keys
  # are available to the SSH client without a separate ssh-agent.
  environment.variables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)";
  };

  # gpg-agent handles SSH; the stock ssh-agent must not run alongside it.
  programs.ssh.startAgent = lib.mkForce false;
}
