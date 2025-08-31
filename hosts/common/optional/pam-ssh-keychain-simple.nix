# Alternative: Simpler PAM + Keychain configuration
# This version uses a login script approach that's more reliable
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Install keychain
  environment.systemPackages = with pkgs; [
    keychain
  ];

  # Enable SSH agent auth for sudo
  security.pam.sshAgentAuth.enable = true;

  # Configure SSH_ASKPASS for GUI password prompts
  environment.sessionVariables = {
    SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  # Create a systemd user service to unlock SSH keys on login
  systemd.user.services.ssh-keychain-unlock = {
    description = "Unlock SSH keys with keychain after login";
    wantedBy = [ "default.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStart = "${pkgs.writeShellScript "unlock-ssh-keys" ''
        # Wait a moment for the desktop to fully load
        sleep 2

        # Initialize keychain with SSH keys
        if command -v keychain >/dev/null 2>&1; then
          # This will prompt for passphrase using SSH_ASKPASS if keys aren't unlocked
          eval $(keychain --eval --agents ssh --timeout 480 id_camelot 2>/dev/null || true)

          # Load YubiKey if present
          if [ -f "$HOME/.ssh/id_yubikey" ]; then
            eval $(keychain --eval --agents ssh --timeout 480 id_yubikey 2>/dev/null || true)
          fi
        fi
      ''}";
    };
  };

  # Also configure shell integration
  environment.shellInit = ''
    # Initialize keychain in shell sessions
    if command -v keychain >/dev/null 2>&1; then
      # Keychain will reuse existing agent and keys
      eval $(keychain --eval --agents ssh --quiet --timeout 480 id_camelot 2>/dev/null || true)

      if [ -f "$HOME/.ssh/id_yubikey" ]; then
        eval $(keychain --eval --agents ssh --quiet --timeout 480 id_yubikey 2>/dev/null || true)
      fi
    fi
  '';
}
