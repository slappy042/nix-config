{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.brave = {
    enable = true;
    package = pkgs.unstable.brave;
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

  # Configure Brave preferences to be ready for sync
  # Use mkOutOfStoreSymlink so Brave can write to the file during runtime
  xdg.configFile."BraveSoftware/Brave-Browser/Default/Preferences".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/dotfiles/nix/config/brave-preferences.json";

  # Initialize the preferences file with our default settings if it doesn't exist
  home.activation.brave-preferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PREFS_FILE="${config.home.homeDirectory}/dev/dotfiles/nix/config/brave-preferences.json"
        PREFS_DIR="$(dirname "$PREFS_FILE")"

        # Create the directory if it doesn't exist
        if [[ ! -d "$PREFS_DIR" ]]; then
          $DRY_RUN_CMD mkdir -p "$PREFS_DIR"
        fi

        # Only create the file if it doesn't already exist
        if [[ ! -f "$PREFS_FILE" ]]; then
          $DRY_RUN_CMD cat > "$PREFS_FILE" << 'EOF'
    ${builtins.toJSON {
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
      };
    }}
    EOF
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
