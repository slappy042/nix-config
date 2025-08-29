# 7days-to-die.nix
# Based on: https://steamcommunity.com/sharedfiles/filedetails/?id=360404397
# 7 Days to Die dedicated server configuration
# wrote with claude sonnet 4

{
  config,
  pkgs,
  lib,
  utils,
  ...
}:
let
  # Import gaming library directly to avoid infinite recursion
  gamingLib = import ./lib.nix { inherit lib; };

  # Set to {id}-{branch}-{password} for betas.
  steam-app = "294420_alpha20.7";

  # Game installation path (using steamcmd +force_install_dir)
  game-dir = "/opt/steam-app-${steam-app}";

  # Create instruction files directly
  serverControlInstructions = pkgs.writeText "server-control.md" ''
      # 7 Days to Die Server Control Instructions

      ## Service Management Commands

      ### Start the service:
      ```bash
      sudo systemctl start sevendtd
      ```

      ### Stop the service:
      ```bash
      sudo systemctl stop sevendtd
      ```

      ### Check service status:
      ```bash
      sudo systemctl status sevendtd
      ```

      ### Enable auto-start on boot:
      ```bash
      sudo systemctl enable sevendtd
      ```

      ### View server logs in real-time:
      ```bash
      sudo journalctl -u sevendtd -f
      ```

      ### View recent server logs:
      ```bash
      sudo journalctl -u sevendtd -n 100
      ```

      ## Configuration Files

    - **Server config**: `${game-dir}/serverconfig.xml`
    - **Server logs**: `${game-dir}/output_log.txt`
      - **Game saves**: `/home/sevendtd/.local/share/7DaysToDie/Saves/`

      ## File Locations

      - **Game installation**: `${game-dir}/`
    - **Server executable**: `${game-dir}/7DaysToDieServer.x86_64`
    - **Server config**: `${game-dir}/serverconfig.xml`
    - **Server logs**: `${game-dir}/output_log.txt`
    - **Mods directory**: `${game-dir}/Mods/`

      ## Server Management

      **Important**: This service is disabled by default to prevent rebuild failures.
      Use the gameserver justfile for management:

      ### Basic Commands:
      ```bash
      # Show all game services status
      just status

      # Start 7DTD server (auto-handles steam dependencies)
      just start 7dtd

      # Stop server
      just stop 7dtd

      # Update game files and restart
      just update 7dtd

      # Show recent logs
      just logs 7dtd

      # Enable/disable auto-start on boot
      just enable 7dtd
      just disable 7dtd
      ```

      ### Manual systemd commands (if needed):
      ```bash
      # Update the game (requires restart):
      sudo systemctl stop sevendtd
      sudo systemctl start steam@294420_alpha20.7
      sudo systemctl start sevendtd

      # Check if server is responding:
      ss -tuln | grep 26900
      ```

      ## Mod Installation Guide

      ### Overview
      This server uses manual mod installation. Mods are installed directly into the server's Mods directory.
      The server must be stopped before installing or updating mods.

      ### Mod Installation Directory
      All mods should be installed to: `${game-dir}/Mods/`

      ### Pre-Installation Steps

      #### 1. Stop the server
      ```bash
      sudo systemctl stop sevendtd
      ```

      #### 2. Create the Mods directory (if it doesn't exist)
      ```bash
      sudo mkdir -p ${game-dir}/Mods
      sudo chown steam:game ${game-dir}/Mods
      ```

      ### Installing Specific Mods

      #### Undead Legacy Mod

      **Source**: https://ul.subquake.com/download

      **Installation steps**:
      1. Download the Undead Legacy mod from the website
      2. Extract the downloaded archive
      3. Copy the mod folder to the Mods directory:
      ```bash
      sudo cp -r /path/to/extracted/UndeadLegacy ${game-dir}/Mods/
      sudo chown -R steam:game ${game-dir}/Mods/UndeadLegacy
      ```

      #### Compo Pack 48.5 for UL

      **Source**: Manual Google Drive download

      **Installation steps**:
      1. Download Compo Pack 48.5 for UL from Google Drive
      2. Extract the downloaded archive
      3. Copy the mod folder to the Mods directory:
      ```bash
      sudo cp -r /path/to/extracted/CompoPack48.5 ${game-dir}/Mods/
      sudo chown -R steam:game ${game-dir}/Mods/CompoPack48.5
      ```

      **Note**: Compo Pack must be installed AFTER Undead Legacy as it's an addon for UL.

      ### General Mod Installation Process

      For any other mods:

      1. **Stop the server**: `sudo systemctl stop sevendtd`
      2. **Download the mod** from its source
      3. **Extract** if it's an archive
      4. **Copy to Mods directory**:
      ```bash
      sudo cp -r /path/to/mod-folder ${game-dir}/Mods/
      ```
      5. **Fix permissions**:
      ```bash
      sudo chown -R steam:game ${game-dir}/Mods/mod-folder-name
      ```
      6. **Start the server**: `sudo systemctl start sevendtd`

      ### Verification

      #### Check installed mods:
      ```bash
      ls -la ${game-dir}/Mods/
      ```

      #### Verify mod loading in logs:
      ```bash
      sudo journalctl -u sevendtd -f
      # or
      tail -f /home/sevendtd/logs/output_log.txt
      ```

      Look for mod loading messages in the server startup logs.

      ### Troubleshooting

      #### Common Issues:
      - **Permission errors**: Make sure all mod files are owned by `steam:game`
      - **Mod conflicts**: Some mods may not be compatible with each other
      - **Server won't start**: Check logs for mod-related errors
      - **Missing dependencies**: Ensure required mods are installed first (e.g., UL before Compo Pack)

      #### File Permissions Fix:
      If you have permission issues:
      ```bash
      sudo chown -R steam:game ${game-dir}/Mods/
      sudo chmod -R 755 ${game-dir}/Mods/
      ```

      ### Important Notes

      - **Backup first**: Consider backing up your save data before installing mods
      - **Mod compatibility**: Ensure mods are compatible with alpha20.7
      - **Load order**: Some mods depend on others (like Compo Pack requiring Undead Legacy)
      - **Server restarts**: Mod changes typically require a server restart
      - **Client compatibility**: Players may need the same mods installed on their clients

      ### Save Data Location
      Your world saves are stored in: `/home/sevendtd/.local/share/7DaysToDie/Saves/`
      Consider backing this up before major mod changes.
  '';
in
lib.mkMerge [
  # Create the 7DTD user
  (gamingLib.createGameUser {
    username = "sevendtd";
    description = "7 Days to Die dedicated server user";
    homeDir = "/home/sevendtd";
  })

  # Create game directories
  (gamingLib.createGameDirectories {
    user = "sevendtd";
    homeDir = "/home/sevendtd";
    logDir = "/home/sevendtd/logs";
  })

  # Register this game service for management tools
  (gamingLib.registerGameService {
    id = "7dtd";
    name = "7 Days to Die";
    description = "7 Days to Die Dedicated Server (Alpha 20.7)";
    unitName = "7dtd-server"; # systemd-run unit name
    steamApp = "294420_alpha20.7";
    gameDir = game-dir;
    executable = "${game-dir}/7DaysToDieServer.x86_64";
    args = [
      "-quit"
      "-batchmode"
      "-nographics"
      "-dedicated"
      "-configfile=${game-dir}/serverconfig.xml"
      "-logfile=${game-dir}/output_log.txt"
    ];
    environment = {
      LD_LIBRARY_PATH = "${game-dir}:${pkgs.glibc}/lib";
    };
    ports = [
      26900
      26901
      26902
    ];
    configFile = "${game-dir}/serverconfig.xml";
    logDir = "${game-dir}";
    user = "sevendtd";
    group = "game";
    workingDirectory = "/home/sevendtd";
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
  }
]
