# Home Manager configuration for keychain SSH agent
# Alternative to system-wide configuration - enables per-user keychain setup
{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Install keychain for the user
  home.packages = with pkgs; [
    keychain
  ];

  # Configure shell to use keychain
  programs.bash.initExtra = lib.mkAfter ''
    # Initialize keychain with SSH keys
    if command -v keychain >/dev/null 2>&1; then
      eval $(keychain --eval --agents ssh --quiet id_camelot)

      # Load YubiKey if present
      if [ -f "$HOME/.ssh/id_yubikey" ]; then
        eval $(keychain --eval --agents ssh --quiet id_yubikey)
      fi
    fi
  '';

  programs.zsh.initExtra = lib.mkAfter ''
    # Initialize keychain with SSH keys
    if command -v keychain >/dev/null 2>&1; then
      eval $(keychain --eval --agents ssh --quiet id_camelot)

      # Load YubiKey if present
      if [ -f "$HOME/.ssh/id_yubikey" ]; then
        eval $(keychain --eval --agents ssh --quiet id_yubikey)
      fi
    fi
  '';

  # Fish shell support
  programs.fish.shellInit = lib.mkAfter ''
    # Initialize keychain with SSH keys
    if command -v keychain >/dev/null 2>&1
      eval (keychain --eval --agents ssh --quiet id_camelot)

      # Load YubiKey if present
      if test -f "$HOME/.ssh/id_yubikey"
        eval (keychain --eval --agents ssh --quiet id_yubikey)
      end
    end
  '';
}
