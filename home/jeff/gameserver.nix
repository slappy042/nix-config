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

    #common/optional/desktops
  ];

  # Deploy gameserver management justfile
  home.file."justfile" = {
    source = ../../hosts/nixos/gameserver/justfile;
    # Make it executable for convenience (though just works with non-executable files too)
    executable = false;
  };
}
