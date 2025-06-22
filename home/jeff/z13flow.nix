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
    common/optional/desktops # default is hyprland
    common/optional/development
    # common/optional/comms
    common/optional/helper-scripts
    common/optional/gaming
    common/optional/media
    common/optional/tools

    common/optional/xdg.nix # file associations
    common/optional/sops.nix
  ];

}
