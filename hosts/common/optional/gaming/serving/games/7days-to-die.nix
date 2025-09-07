# 7days-to-die.nix
# Based on: https://steamcommunity.com/sharedfiles/filedetails/?id=360404397
# 7 Days to Die dedicated server configuration
# wrote with claude sonnet 4 and xGrok

{
  config,
  pkgs,
  lib,
  utils,
  ...
}:
let
  # Import gaming library directly to avoid infinite recursion
  gamingLib = import ./lib.nix { inherit lib config; };

  # Set to {id}-{branch}-{password} for betas.
  steamApp = "294420_alpha20.7";

  gameShortName = "7dtd";

  # Game installation path (using steamcmd +force_install_dir)
  gameDir = "${config.users.users.${config.hostSpec.username}.home}/games/steam/${gameShortName}";

  # Symlink for convenience
  gameSymlink = "${config.users.users.${config.hostSpec.username}.home}/${gameShortName}";

  # Create 7DTD-specific server control instructions file
  dtdServerControlInstructions = ./docs/7dtd-mods.md;
in
lib.mkMerge [
  # Create game directories and symlink
  (gamingLib.createGameDirectories {
    user = config.hostSpec.username;
    group = "users";
    homeDir = config.users.users.${config.hostSpec.username}.home;
    logDir = "${config.users.users.${config.hostSpec.username}.home}/logs";
    gameDir = gameDir;
    gameSymlink = gameSymlink;
    extraDirs = [ ];
  })

  # Register this game service for management tools
  (gamingLib.registerGameService {
    id = "7dtd";
    name = "7 Days to Die";
    description = "7 Days to Die Dedicated Server (Alpha 20.7)";
    unitName = "7dtd-server"; # systemd-run unit name
    steamApp = steamApp;
    gameDir = gameDir;
    executable = "${gameDir}/7DaysToDieServer.x86_64";
    args = [
      "-quit"
      "-batchmode"
      "-nographics"
      "-dedicated"
      "-configfile=${gameDir}/serverconfig.xml"
      "-logfile=${gameDir}/output_log.txt"
    ];
    environment = {
      LD_LIBRARY_PATH = "${gameDir}:${pkgs.glibc}/lib";
    };
    ports = [
      26900
      26901
      26902
    ];
    configFile = "${gameDir}/serverconfig.xml";
    logDir = "${gameDir}";
    user = config.hostSpec.username;
    group = "users";
    workingDirectory = config.users.users.${config.hostSpec.username}.home;
    cleanFilters = [
      # Add specific paths to clean for 7 Days to Die user data
      # Examples:
      # "~/.local/share/7DaysToDie"
      # "~/.config/unity3d/The Fun Pimps/7 Days To Die"
      # "~/.cache/unity3d/The Fun Pimps/7 Days To Die"
    ];
  })

  # Firewall configuration only - no systemd service needed
  # Games are managed imperatively via justfile + systemd-run
  {

    # Basic firewall configuration for 7DTD
    networking.firewall = {
      allowedTCPPorts = [ 26900 ]; # Game port
      allowedUDPPorts = [
        26900
        26901
        26902
        26903
      ]; # Game ports + LiteNetLib
      # Note: Port 8081 (telnet) and 8080 (webadmin) are not opened for security
    };

    # Create 7DTD documentation in primary user's home directory
    home-manager.users.${config.hostSpec.username}.home.file."7dtd-mods.md" = {
      source = ./docs/7dtd-mods.md;
    };
  }
]
