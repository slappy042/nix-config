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
    };
  };

  preferencesFile = "${config.home.homeDirectory}/dev/dotfiles/nix/config/brave-preferences.json";
in
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

  # Ensure the dotfiles directory exists
  home.file."dev/dotfiles/nix/config/.keep".text = "";

  # Create the preferences file if it doesn't exist
  home.file."dev/dotfiles/nix/config/brave-preferences.json" = {
    text = builtins.toJSON defaultPreferences;
    # Only create if file doesn't exist (won't overwrite existing file)
    force = false;
  };

  # Symlink Brave preferences to the external file
  xdg.configFile."BraveSoftware/Brave-Browser/Default/Preferences".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink preferencesFile
  );

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
