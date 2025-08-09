{ ... }:
{
  imports = [
    #
    # ========== Required Configs ==========
    #
    common/core

    #
    # ========== Host-specific Optional Configs ==========
    #
    common/optional/browsers
    # common/optional/desktops # default is hyprland
    common/optional/development
    common/optional/development/vscode.nix # vscode and extensions
    # common/optional/comms
    common/optional/helper-scripts
    common/optional/gaming
    common/optional/media
    common/optional/tools

    common/optional/xdg.nix # file associations
    common/optional/sops.nix
    common/optional/zellij.nix # terminal multiplexer
  ];

  #
  # ========== Host-specific Monitor Spec ==========
  #
  # This uses the nix-config/modules/home/montiors.nix module which defaults to enabled.
  # Your nix-config/home-manger/<user>/common/optional/desktops/foo.nix WM config should parse and apply these values to it's monitor settings
  # If on hyprland, use `hyprctl monitors` to get monitor info.
  # https://wiki.hyprland.org/Configuring/Monitors/
  #    ------
  # | Internal |
  # | Display  |
  #    ------
  monitors = [
    {
      name = "eDP-1";
      width = 2560;
      height = 1600;
      refreshRate = 180;
      y = -1600;
      # primary = true;
      #vrr = 1;
    }
    {
      name = "DP-8";
      width = 3840;
      height = 2160;
      refreshRate = 120;
      primary = true;
      #vrr = 1;
    }
    {
      name = "DP-9";
      width = 2560;
      height = 1440;
      refreshRate = 60;
      enabled = false; # disabled by default
    }
    {
      name = "DP-10";
      width = 2560;
      height = 1440;
      refreshRate = 60;
      enabled = false; # disabled by default
    }
  ];

}
