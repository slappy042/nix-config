# PAM + Keychain configuration for automatic SSH key unlock
# Works with any desktop environment (KDE, GNOME, Hyprland) or no DE at all (VT console)
# Automatically unlocks SSH keys when you login (if login password = SSH key passphrase)
{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Simple script to unlock SSH keys using keychain after login
  unlock-ssh-keys = pkgs.writeShellScriptBin "unlock-ssh-keys" ''
    #!/usr/bin/env bash

    # Get user info
    USER_NAME="''${PAM_USER:-$(whoami)}"
    USER_HOME="''${HOME:-$(getent passwd "$USER_NAME" | cut -d: -f6)}"

    # Only proceed if we have the necessary tools and keys
    if ! command -v keychain >/dev/null 2>&1; then
      exit 0
    fi

    # Check for SSH keys
    SSH_KEYS=""
    for key in id_camelot id_yubikey; do
      if [ -f "$USER_HOME/.ssh/$key" ]; then
        SSH_KEYS="$SSH_KEYS $key"
      fi
    done

    if [ -z "$SSH_KEYS" ]; then
      exit 0
    fi

    # Set up environment
    export HOME="$USER_HOME"
    cd "$USER_HOME"

    # Use keychain with timeout and noask for non-interactive unlock
    # This will use ssh-askpass if available, or prompt in terminal
    eval $(keychain --eval --agents ssh --timeout 480 --quiet $SSH_KEYS 2>/dev/null || true)
  '';
in
{
  # Install required packages
  environment.systemPackages = with pkgs; [
    keychain
    openssh # Ensures ssh-askpass is available
  ];

  # Enable SSH agent auth for sudo
  security.pam.sshAgentAuth.enable = true;

  # Configure SSH_ASKPASS to use the desktop's password prompt
  environment.sessionVariables = {
    SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  # PAM configuration to initialize keychain on login
  security.pam.services.login = {
    text = lib.mkAfter ''
      # Initialize SSH keychain after successful login
      session optional ${pkgs.pam}/lib/security/pam_exec.so ${unlock-ssh-keys}/bin/unlock-ssh-keys
    '';
  };

  # Also for display manager logins
  security.pam.services.sddm = {
    text = lib.mkAfter ''
      # Initialize SSH keychain after successful GUI login
      session optional ${pkgs.pam}/lib/security/pam_exec.so ${unlock-ssh-keys}/bin/unlock-ssh-keys
    '';
  };

  # Configure keychain in shell sessions
  environment.shellInit = ''
    # Initialize keychain with SSH keys
    if command -v keychain >/dev/null 2>&1; then
      # Keychain will reuse existing agent and keys if already loaded
      eval $(keychain --eval --agents ssh --quiet --timeout 480 id_camelot 2>/dev/null || true)

      # Load YubiKey if present
      if [ -f "$HOME/.ssh/id_yubikey" ]; then
        eval $(keychain --eval --agents ssh --quiet --timeout 480 id_yubikey 2>/dev/null || true)
      fi
    fi
  '';

  # Note:
  # - If your login password = SSH key passphrase, keychain will use SSH_ASKPASS
  # - SSH_ASKPASS will prompt with the same GUI password dialog you used to login
  # - Keychain caches unlocked keys for 8 hours (480 minutes)
  # - Keys remain unlocked across all terminals and SSH sessions
}
