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
    common/optional/sops.nix
    common/optional/helper-scripts
    common/optional/development

    #common/optional/desktops
  ];
}
