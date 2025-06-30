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
      "--sync-url=https://sync-v2.brave.com"
    ];
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "brave-browser.desktop" ];
    "text/xml" = [ "brave-browser.desktop" ];
    "x-scheme-handler/http" = [ "brave-browser.desktop" ];
    "x-scheme-handler/https" = [ "brave-browser.desktop" ];
  };

  # Configure Brave preferences to be ready for sync
  home.file.".config/BraveSoftware/Brave-Browser/Default/Preferences".source =
    pkgs.writeText "brave-preferences"
      (
        builtins.toJSON {
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
        }
      );
}
