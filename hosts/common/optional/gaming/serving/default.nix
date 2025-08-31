{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./steamcmd.nix
    # ./valheim.nix
    # ./satisfactory.nix
    ./7days-to-die.nix
    # ... other games
  ];

  # System packages needed for game service management
  environment.systemPackages = with pkgs; [
    jq # For parsing JSON game service registry and marker files
    patchelf # For fixing NixOS executable interpreter paths
  ];

  # Configure primary user's home directory with home-manager
  home-manager.users.${config.hostSpec.username} = {
    home.file = {
      # Main game control documentation
      "game-control.md" = {
        source = ./docs/game-control.md;
      };
      # Services directory for game registry
      "services/.keep".text = "";
    };
  };
}
