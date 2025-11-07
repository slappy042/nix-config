# Home Manager GPG configuration with SSH keygrip setup
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Disable SSH agent since we're using GPG agent
  services.ssh-agent.enable = lib.mkForce false;

  # no settings needed here because we're just using gpg as ssh-agent
  # but we do need the gpg program for handling keygrips
  programs.gpg.enable = true;

  # Shell initialization to ensure GPG_TTY is set correctly
  programs.zsh.initContent = ''
    export GPG_TTY=$(tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

  programs.bash.initExtra = ''
    export GPG_TTY=$(tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  '';

  # Create activation script to pre-load SSH keys for PAM integration
  # 1. Load SSH keys into GPG agent (converts & saves to ~/.gnupg; auto-populates sshcontrol with keygrips)
  # 2. Recreate pam-gnupg with keygrips from SOPS
  home.activation.setupGpgSshKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Ensure GPG directory exists
        mkdir -p ~/.gnupg
        chmod 700 ~/.gnupg

        # Set SSH_AUTH_SOCK to GPG agent socket
        export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)

        echo "Pre-loading SSH keys into GPG agent for PAM integration..."

        # Pre-load SSH keys from ~/.ssh/ into GPG agent
        # This is necessary for PAM integration to work properly
        for ssh_key in ~/.ssh/id_*; do
          # Skip if no files match the pattern or if it's a public key
          [ -f "$ssh_key" ] || continue
          [[ "$ssh_key" == *.pub ]] && continue

          key_name=$(basename "$ssh_key")
          echo "Pre-loading SSH key into GPG agent: $key_name"

          # Add the key to GPG agent (this converts and stores it in GPG format)
          # Use || true to ignore errors if key is already loaded
          ${pkgs.openssh}/bin/ssh-add "$ssh_key" 2>/dev/null || true
        done

        # Extract keygrips from SOPS-decrypted files for PAM integration
        echo "Setting up PAM integration using SOPS-stored keygrips..."

        # Always recreate pam-gnupg file with keygrips from SOPS
        cat > ~/.pam-gnupg << 'EOF'
    # PAM-GNUPG keygrips file
    # Keygrips for keys that should be unlocked during PAM authentication
    # Populated from SOPS-encrypted keygrip data

    EOF
        chmod 600 ~/.pam-gnupg

        # Add keygrips from SOPS-decrypted files
        keygrip_dir="$HOME/.ssh/.keygrips"
        if [ -d "$keygrip_dir" ]; then
          echo "Adding keygrips from SOPS to ~/.pam-gnupg..."
          for keygrip_file in "$keygrip_dir"/*_keygrip; do
            if [ -f "$keygrip_file" ]; then
              keygrip=$(cat "$keygrip_file" 2>/dev/null | tr -d '\n\r' || true)
              # Check if keygrip is exactly 40 hex characters (GPG keygrip format)
              if echo "$keygrip" | grep -q '^[A-F0-9]\{40\}$'; then
                echo "$keygrip" >> ~/.pam-gnupg
                echo "Added SOPS keygrip for PAM unlock: $keygrip (from $(basename "$keygrip_file"))"
              fi
            fi
          done
        else
          echo "No SOPS keygrip directory found at $keygrip_dir"
        fi

        # List currently loaded keys
        loaded_keys=$(${pkgs.openssh}/bin/ssh-add -l 2>/dev/null || echo "No keys loaded yet")
        echo "Keys currently in GPG agent: $loaded_keys"

        echo ""
        echo "Setup complete! SSH keys are pre-loaded for PAM integration."
        echo "On next login, pam_gnupg will automatically unlock these keys using your login password."
  '';

}
