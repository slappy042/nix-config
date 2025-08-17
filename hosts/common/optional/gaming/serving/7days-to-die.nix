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
  # Set to {id}-{branch}-{password} for betas.
  steam-app = "294420_alpha20.7";
in
{
  users.users.sevendtd = {
    isSystemUser = true;
    # 7DTD puts save data in the home directory under .local/share/7DaysToDie/
    home = "/home/sevendtd";
    createHome = true;
    homeMode = "750";
    group = "sevendtd";
  };

  users.groups.sevendtd = { };

  systemd.services.sevendtd = {
    wantedBy = [ "multi-user.target" ];

    # Install the game before launching.
    wants = [ "steam@${steam-app}.service" ];
    after = [ "steam@${steam-app}.service" ];

    serviceConfig = {
      ExecStart = utils.escapeSystemdExecArgs [
        "/opt/steam-app-${steam-app}/7DaysToDieServer.x86_64"
        "-quit"
        "-batchmode"
        "-nographics"
        "-dedicated"
        "-configfile=/home/sevendtd/serverconfig.xml"
        "-logfile=/home/sevendtd/logs/output_log.txt"
      ];
      Nice = "-5";
      PrivateTmp = true;
      Restart = "always";
      User = "sevendtd";
      WorkingDirectory = "~";
      # Create logs directory
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/sevendtd/logs";
    };
    environment = {
      # Set LD_LIBRARY_PATH for 7DTD server requirements
      LD_LIBRARY_PATH = "/opt/steam-app-${steam-app}:${pkgs.glibc}/lib";
    };
  };

  # Create default server configuration and instructions
  systemd.tmpfiles.rules = [
    "d /home/sevendtd 0750 sevendtd sevendtd - -"
    "d /home/sevendtd/logs 0750 sevendtd sevendtd - -"
    "f /home/sevendtd/serverconfig.xml 0640 sevendtd sevendtd - -"
  ];

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

  # Write service control instructions
  environment.etc."sevendtd-instructions".text = ''
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

    ### Disable auto-start on boot:
    ```bash
    sudo systemctl disable sevendtd
    ```

    ## Viewing Logs

    ### Recent systemd logs:
    ```bash
    sudo journalctl -u sevendtd
    ```

    ### Follow logs in real-time:
    ```bash
    sudo journalctl -u sevendtd -f
    ```

    ### Last 50 lines:
    ```bash
    sudo journalctl -u sevendtd -n 50
    ```

    ### Game-specific logs:
    ```bash
    tail -f /home/sevendtd/logs/output_log.txt
    ```

    ## Important Notes

    - **Steam download happens first**: When you start the service, it will automatically download/update the 7DTD server files first
    - **Initial startup may be slow**: First run downloads ~1-2GB, be patient
    - **Configuration**: Edit `/home/sevendtd/serverconfig.xml` to configure server settings
    - **Auto-restart**: Service automatically restarts if it crashes
    - **App ID**: Using 294420-alpha20.7 (7 Days to Die alpha20.7 beta)

    ## File Locations

    - Server executable: `/opt/steam-app-294420-alpha20.7/7DaysToDieServer.x86_64`
    - Configuration: `/home/sevendtd/serverconfig.xml`
    - Logs: `/home/sevendtd/logs/output_log.txt`
    - Save data: `/home/sevendtd/.local/share/7DaysToDie/Saves/`

    ## Network Ports

    The following ports are opened in the firewall:
    - TCP 26900 (main game port)
    - UDP 26900, 26901, 26902, 26903 (game ports + LiteNetLib)

    Note: Telnet (8081) and webadmin (8080) ports are NOT opened for security reasons.
  '';

  # Write mod installation instructions
  environment.etc."sevendtd-mod-instructions".text = ''
    # 7 Days to Die Server - Mod Installation Guide

    ## Overview
    This server uses manual mod installation. Mods are installed directly into the server's Mods directory.
    The server must be stopped before installing or updating mods.

    ## Mod Installation Directory
    All mods should be installed to: `/opt/steam-app-294420-alpha20.7/Mods/`

    ## Pre-Installation Steps

    ### 1. Stop the server
    ```bash
    sudo systemctl stop sevendtd
    ```

    ### 2. Create the Mods directory (if it doesn't exist)
    ```bash
    sudo mkdir -p /opt/steam-app-294420-alpha20.7/Mods
    sudo chown steam:steam /opt/steam-app-294420-alpha20.7/Mods
    ```

    ## Installing Specific Mods

    ### Undead Legacy Mod

    **Source**: https://ul.subquake.com/download

    **Installation steps**:
    1. Download the Undead Legacy mod from the website
    2. Extract the downloaded archive
    3. Copy the mod folder to the Mods directory:
    ```bash
    sudo cp -r /path/to/extracted/UndeadLegacy /opt/steam-app-294420-alpha20.7/Mods/
    sudo chown -R steam:steam /opt/steam-app-294420-alpha20.7/Mods/UndeadLegacy
    ```

    ### Compo Pack 48.5 for UL

    **Source**: Manual Google Drive download

    **Installation steps**:
    1. Download Compo Pack 48.5 for UL from Google Drive
    2. Extract the downloaded archive
    3. Copy the mod folder to the Mods directory:
    ```bash
    sudo cp -r /path/to/extracted/CompoPack48.5 /opt/steam-app-294420-alpha20.7/Mods/
    sudo chown -R steam:steam /opt/steam-app-294420-alpha20.7/Mods/CompoPack48.5
    ```

    **Note**: Compo Pack must be installed AFTER Undead Legacy as it's an addon for UL.

    ## General Mod Installation Process

    For any other mods:

    1. **Stop the server**: `sudo systemctl stop sevendtd`
    2. **Download the mod** from its source
    3. **Extract** if it's an archive
    4. **Copy to Mods directory**:
    ```bash
    sudo cp -r /path/to/mod-folder /opt/steam-app-294420-alpha20.7/Mods/
    ```
    5. **Fix permissions**:
    ```bash
    sudo chown -R steam:steam /opt/steam-app-294420-alpha20.7/Mods/mod-folder-name
    ```
    6. **Start the server**: `sudo systemctl start sevendtd`

    ## Verification

    ### Check installed mods:
    ```bash
    ls -la /opt/steam-app-294420-alpha20.7/Mods/
    ```

    ### Verify mod loading in logs:
    ```bash
    sudo journalctl -u sevendtd -f
    # or
    tail -f /home/sevendtd/logs/output_log.txt
    ```

    Look for mod loading messages in the server startup logs.

    ## Troubleshooting

    ### Common Issues:
    - **Permission errors**: Make sure all mod files are owned by `steam:steam`
    - **Mod conflicts**: Some mods may not be compatible with each other
    - **Server won't start**: Check logs for mod-related errors
    - **Missing dependencies**: Ensure required mods are installed first (e.g., UL before Compo Pack)

    ### File Permissions Fix:
    If you have permission issues:
    ```bash
    sudo chown -R steam:steam /opt/steam-app-294420-alpha20.7/Mods/
    sudo chmod -R 755 /opt/steam-app-294420-alpha20.7/Mods/
    ```

    ## Important Notes

    - **Backup first**: Consider backing up your save data before installing mods
    - **Mod compatibility**: Ensure mods are compatible with alpha20.7
    - **Load order**: Some mods depend on others (like Compo Pack requiring Undead Legacy)
    - **Server restarts**: Mod changes typically require a server restart
    - **Client compatibility**: Players may need the same mods installed on their clients

    ## Save Data Location
    Your world saves are stored in: `/home/sevendtd/.local/share/7DaysToDie/Saves/`
    Consider backing this up before major mod changes.
  '';

  systemd.services.sevendtd-setup = {
    description = "Copy 7DTD instructions to user home";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "sevendtd-setup" ''
        ${pkgs.coreutils}/bin/cp /etc/sevendtd-instructions /home/sevendtd/7dtd.md
        ${pkgs.coreutils}/bin/cp /etc/sevendtd-mod-instructions /home/sevendtd/mods.md
        ${pkgs.coreutils}/bin/chown sevendtd:sevendtd /home/sevendtd/7dtd.md
        ${pkgs.coreutils}/bin/chown sevendtd:sevendtd /home/sevendtd/mods.md
      '';
      RemainAfterExit = true;
    };
  };
}
