{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Default preferences to initialize the external preferences file
  defaultPreferences = {
    # Sync preferences - enable sync features
    sync_promo = {
      show_on_first_run_allowed = true;
      user_skipped = false;
    };

    sync = {
      suppress_start_after_signin = false;
      requested = true;
    };

    # Browser signin configuration
    signin = {
      allowed = true;
    };

    # First run preferences
    browser = {
      show_home_button = true;
      check_default_browser = false;
    };

    # Privacy settings that work well with sync
    profile = {
      default_content_setting_values = {
        cookies = 1; # Allow cookies for sync
      };
    };

    # Disable Brave Rewards
    brave = {
      rewards = {
        enabled = false;
        show_brave_rewards_button_in_location_bar = false;
      };
      # Also disable ads
      ads = {
        enabled = false;
      };
      # Disable rewards in new tab page
      new_tab_page = {
        show_rewards = false;
        show_together = false;
      };
    };
  };

  preferencesFile = "${config.home.homeDirectory}/dev/dotfiles/nix/config/brave-preferences.json";
in
{
  programs.brave = {
    enable = true;
    package = pkgs.unstable.brave;
    extensions = [
      "kbmfpngjjgdllneeigpgjifpgocmfgmb" # RES
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
    ];

    commandLineArgs = [
      "--no-default-browser-check"
      "--restore-last-session"
      "--enable-sync"
      "--sync-url=https://sync-v2.brave.com/v2"
    ];
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "brave-browser.desktop" ];
    "text/xml" = [ "brave-browser.desktop" ];
    "x-scheme-handler/http" = [ "brave-browser.desktop" ];
    "x-scheme-handler/https" = [ "brave-browser.desktop" ];
  };

  # Create initial Brave preferences file only if it doesn't exist
  # This allows home-manager to set up initial config while letting Brave write to it normally
  home.activation.createBravePreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        preferencesFile="${config.home.homeDirectory}/.config/BraveSoftware/Brave-Browser/Default/Preferences"

        # Only create the file if it doesn't exist (first installation)
        if [ ! -f "$preferencesFile" ]; then
          echo "Creating initial Brave preferences file with sync configuration..."

          # Create the directory structure if it doesn't exist
          mkdir -p "$(dirname "$preferencesFile")"

          # Create the initial preferences file
          cat > "$preferencesFile" << 'EOF'
    ${builtins.toJSON defaultPreferences}
    EOF

          # Ensure the file is writable by the user
          chmod 644 "$preferencesFile"
          echo "Brave preferences initialized. Brave can now modify this file normally."
        else
          echo "Brave preferences file already exists, leaving it unchanged."
        fi
  '';

  # Install the sync code management scripts
  home.file.".config/brave-sync-codes/get_25th_word.sh" = {
    source = ./get_25th_word.sh;
    executable = true;
  };

  home.file.".config/brave-sync-codes/show-sync-codes.sh" = {
    source = ./show-sync-codes.sh;
    executable = true;
  };
}
