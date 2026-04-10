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
          ${pkgs.openssh}/bin/ssh-add "$ssh_key" 2>/dev/null || {
            echo "Failed to add $key_name (may be encrypted - will be unlocked on login)"
          }
        done

        # Create sshcontrol file (GPG agent should have populated it now)
        if [ ! -f ~/.gnupg/sshcontrol ]; then
          cat > ~/.gnupg/sshcontrol << 'EOF'
    # GPG agent SSH control file
    # Contains keygrips for SSH keys managed by GPG agent

    EOF
          chmod 600 ~/.gnupg/sshcontrol
        fi

        # Extract keygrips from SOPS-decrypted files for PAM integration
        echo "Setting up PAM integration using SOPS-stored keygrips..."

        # Create pam-gnupg file with keygrips from SOPS
        if [ ! -f ~/.pam-gnupg ]; then
          cat > ~/.pam-gnupg << 'EOF'
    # PAM-GNUPG keygrips file
    # Keygrips for keys that should be unlocked during PAM authentication
    # Populated from SOPS-encrypted keygrip data

    EOF
          chmod 600 ~/.pam-gnupg
        fi

        # Add keygrips from SOPS-decrypted files
        keygrip_dir="$HOME/.ssh/.keygrips"
        if [ -d "$keygrip_dir" ]; then
          echo "Adding keygrips from SOPS to ~/.pam-gnupg..."
          for keygrip_file in "$keygrip_dir"/*_keygrip; do
            if [ -f "$keygrip_file" ]; then
              keygrip=$(cat "$keygrip_file" 2>/dev/null | tr -d '\n\r' || true)
              if [ -n "$keygrip" ] && [ ''${#keygrip} -eq 40 ]; then
                if ! grep -q "$keygrip" ~/.pam-gnupg 2>/dev/null
                then
                  echo "$keygrip" >> ~/.pam-gnupg
                  echo "Added SOPS keygrip for PAM unlock: $keygrip (from $(basename "$keygrip_file"))"
                fi
              fi
            fi
          done
        else
          echo "No SOPS keygrip directory found at $keygrip_dir"
          echo "Falling back to runtime keygrip extraction..."

          # Fallback: try to get keygrips from GPG agent if available
          sleep 2
          keygrips=$(${pkgs.gnupg}/bin/gpg-connect-agent 'keyinfo --ssh-list' /bye 2>/dev/null | grep '^S KEYINFO' | awk '{print $3}' || true)

          if [ -n "$keygrips" ]; then
            echo "Adding runtime keygrips to ~/.pam-gnupg..."
            for keygrip in $keygrips; do
              if ! grep -q "$keygrip" ~/.pam-gnupg 2>/dev/null; then
                echo "$keygrip" >> ~/.pam-gnupg
                echo "Added runtime keygrip: $keygrip"
              fi
            done
          fi
        fi

        # List currently loaded keys
        loaded_keys=$(${pkgs.openssh}/bin/ssh-add -l 2>/dev/null || echo "No keys loaded yet")
        echo "Keys currently in GPG agent: $loaded_keys"

        echo ""
        echo "Setup complete! SSH keys are pre-loaded for PAM integration."
        echo "On next login, pam_gnupg will automatically unlock these keys using your login password."
  '';

}
