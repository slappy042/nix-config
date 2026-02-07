# OpenSSH configuration with GPG agent integration
# This module includes GPG agent support for SSH authentication
# GPG agent handles SSH keys and integrates with PAM for password-based unlocking
{
  lib,
  config,
  pkgs,
  ...
}:
let
  sshPort = config.hostSpec.networking.ports.tcp.ssh;

  # Sops needs access to the keys before the persist dirs are even mounted; so
  # just persisting the keys won't work, we must point at /persist
  #FIXME(impermanence): refactor this to how fb did it
  hasOptinPersistence = false;
in

{
  # GPG Agent configuration with SSH support and PAM integration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;

    # Use curses-based pinentry instead of GUI
    pinentryPackage = pkgs.pinentry-curses;

    # GPG agent settings
    settings = {
      # Extended cache times for convenience
      default-cache-ttl = 60480000; # 1 week (default is much shorter)
      default-cache-ttl-ssh = 60480000; # 1 week
      max-cache-ttl = 120960000; # 2 weeks
      max-cache-ttl-ssh = 120960000; # 2 weeks

      # Allow loopback pinentry (useful for headless systems)
      allow-loopback-pinentry = "";

      # Allow preset passphrases (required for PAM integration)
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

  # PAM configuration for gnupg
  security.pam.services = {
    login.gnupg = {
      enable = true;
      noAutostart = true;
      storeOnly = false;
    };

    # re-unlock GPG keys when sudo is used
    sudo.gnupg = {
      enable = true;
      noAutostart = true;
      storeOnly = false;
    };

    # Also enable for display managers if they exist
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

  # Environment setup for GPG
  environment.variables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)";
  };

  # OpenSSH server configuration
  services.openssh = {
    enable = true;
    ports = [ sshPort ];

    settings = {
      # Harden
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      # Automatically remove stale sockets
      StreamLocalBindUnlink = "yes";
      # Allow forwarding ports to everywhere
      GatewayPorts = "clientspecified";
    };

    hostKeys = [
      {
        path = "${lib.optionalString hasOptinPersistence "/persist"}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Disable the default SSH agent since we're using GPG agent
  programs.ssh.startAgent = lib.mkForce false;

  # yubikey login / sudo
  security.pam = {
    rssh.enable = true;
    services.sudo.rssh = true;
  };

  networking.firewall.allowedTCPPorts = [ sshPort ];
}
