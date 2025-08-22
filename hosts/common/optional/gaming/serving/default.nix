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
    jq # For parsing JSON game service registry
  ];

  # Create the /etc/gameserver directory structure
  systemd.tmpfiles.rules = [
    "d /etc/gameserver 0755 root root - -"
    "d /etc/gameserver/services 0755 root root - -"
  ];

  # Create the shared game group for all gaming services
  users.groups.game = { };

  # Add the primary user to the game group so they can manage all gaming service files
  users.users.${config.hostSpec.username}.extraGroups = [ "game" ];
}
