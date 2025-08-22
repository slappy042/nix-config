# steamcmd.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Create instruction files directly
  steamInstructions = pkgs.writeText "steamcmd-instructions.md" ''
    # SteamCMD Service Control Instructions

    ## Overview
    The steam@ service is a template service that downloads and updates Steam applications.
    Each game server depends on this service to install/update the game files.

    ## Service Usage

    ### Download/Update a Steam App:
    ```bash
    # Format: steam@{APPID}_{BRANCH}_{PASSWORD}
    sudo systemctl start steam@294420_alpha20.7  # 7 Days to Die alpha20.7
    sudo systemctl start steam@896660            # Valheim (no beta)
    ```

    ### Check download status:
    ```bash
    sudo systemctl status steam@294420_alpha20.7
    ```

    ### View download logs:
    ```bash
    sudo journalctl -u steam@294420_alpha20.7 -f
    ```

    ### Force re-download (if corrupted):
    ```bash
    sudo systemctl stop steam@294420_alpha20.7
    sudo rm -rf /opt/steam-app-294420_alpha20.7
    sudo systemctl start steam@294420_alpha20.7
    ```

    ## File Locations

    ### Steam Installation:
    - **Steam home**: `/opt/steam/`
    - **SteamCMD binary**: Available in system PATH

    ### Downloaded Apps:
    Apps are downloaded to `/opt/steam-app-{APPID}_{BRANCH}/`

    ### Completion Tracking:
    Each successful download creates a completion marker:
    - **Marker file**: `/opt/steam-app-{APPID}_{BRANCH}/.steamcmd-completed`
    - **Content**: Timestamp and instance info (e.g., "2025-08-22T10:45:02-07:00:294420_alpha20.7")
    - **Purpose**: Other services can check this file to ensure steam download completed

    Examples:
    - **7 Days to Die**: `/opt/steam-app-294420_alpha20.7/`
    - **Valheim**: `/opt/steam-app-896660/`

    ## Common Steam App IDs

    | Game | App ID | Branch | Full Service Name |
    |------|---------|---------|-------------------|
    | 7 Days to Die | 294420 | alpha20.7 | steam@294420_alpha20.7 |
    | Valheim | 896660 | (none) | steam@896660 |
    | Satisfactory | 1690800 | experimental | steam@1690800_experimental |

    ## Adding New Games

    To add a new Steam app:

    1. **Find the App ID**: Look up the dedicated server App ID on Steam
    2. **Determine branch**: Check if you need a specific branch (alpha, beta, etc.)
    3. **Start the service**: `sudo systemctl start steam@{APPID}_{BRANCH}`

    ### Beta/Branch Format:
    ```bash
    # No beta: steam@APPID
    sudo systemctl start steam@896660

    # With beta branch: steam@APPID_BRANCH
    sudo systemctl start steam@294420_alpha20.7

    # With beta + password: steam@APPID_BRANCH_PASSWORD
    sudo systemctl start steam@123456_experimental_secretpassword
    ```

    ## Troubleshooting

    ### Common Issues:

    #### Download Fails:
    ```bash
    # Check logs for errors
    sudo journalctl -u steam@294420_alpha20.7

    # Try restarting steam service
    sudo systemctl restart steam@294420_alpha20.7
    ```

    #### Permission Issues:
    ```bash
    # Fix ownership (should be steam:game)
    sudo chown -R steam:game /opt/steam-app-*
    ```

    #### Disk Space:
    ```bash
    # Check available space
    df -h /opt

    # Clean old downloads if needed
    sudo rm -rf /opt/steam-app-old-version/
    ```

    #### Network Issues:
    - Steam downloads require internet access
    - Downloads can be large (1-5GB per game)
    - Consider running during off-peak hours

    ## Service Dependencies

    Game servers typically depend on the steam@ service:
    ```
    gameserver.service
        ├── wants: steam@APPID.service
        └── after: steam@APPID.service
    ```

    This ensures the game files are downloaded before the game server starts.

    ## Maintenance

    ### Update All Games:
    ```bash
    # Stop all game servers first
    sudo systemctl stop sevendtd
    sudo systemctl stop valheim

    # Update game files
    sudo systemctl start steam@294420_alpha20.7
    sudo systemctl start steam@896660

    # Restart game servers
    sudo systemctl start sevendtd
    sudo systemctl start valheim
    ```

    ### Check App Versions:
    ```bash
    # Look for version files in the app directory
    find /opt/steam-app-* -name "version*" -o -name "*.txt" | head -10
    ```

    ## File Permissions

    All Steam app files are owned by `steam:game`:
    - User: `steam` (runs the download service)
    - Group: `game` (allows jeff and other game services to access)
    - Permissions: 775 for directories, 664 for files

    This allows jeff to manage game files and other game services to read them.
  '';
in
{
  users.users.steam = {
    isSystemUser = true;
    group = "game";
    home = "/opt/steam";
    createHome = true;
  };

  # No need for a separate steam group - we use the shared game group

  # Create instructions file in steam user's home directory
  systemd.tmpfiles.rules = [
    "d /opt/steam 0775 steam game - -"
    "C /opt/steam/README-steamcmd.md 0640 steam game - ${steamInstructions}"
  ];

  systemd.services."steam@" = {
    unitConfig = {
      StopWhenUnneeded = true;
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "+${pkgs.bash}/bin/bash -c 'mkdir -p /opt/steam-app-%i && chown steam:game /opt/steam-app-%i'";
      ExecStart = "${
        pkgs.resholve.writeScript "steam"
          {
            interpreter = "${pkgs.zsh}/bin/zsh";
            inputs = with pkgs; [
              coreutils
              patchelf
              steamcmd
            ];
            execer = with pkgs; [
              "cannot:${steamcmd}/bin/steamcmd"
            ];
          }
          ''
            set -eux

            instance=''${1:?Instance Missing}
            eval 'args=(''${(@s:_:)instance})'
            app=''${args[1]:?App ID missing}
            beta=''${args[2]:-}
            betapass=''${args[3]:-}

            dir=/opt/steam-app-$instance

            # Remove any existing completion marker to prevent race conditions
            marker_file="$dir/.steamcmd-completed"
            rm -f "$marker_file"

            cmds=(
              +force_install_dir $dir
              +login anonymous
              +app_update $app validate
            )

            if [[ $beta ]]; then
              cmds+=(-beta $beta)
              if [[ $betapass ]]; then
                cmds+=(-betapassword $betapass)
              fi
            fi

            cmds+=(+quit)

            steamcmd $cmds

            # Fix executable permissions and interpreter paths
            if [[ -d $dir ]]; then
              for f in $dir/*; do
                if [[ -f $f && -x $f ]]; then
                  # Update the interpreter to the path on NixOS.
                  patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $f || true
                fi
              done
            fi

            # Create completion marker with timestamp and instance info
            marker_file="$dir/.steamcmd-completed"
            echo "$(date -Iseconds):$instance" > "$marker_file"
            chown steam:game "$marker_file"
          ''
      } %i";
      PrivateTmp = true;
      Restart = "on-failure";
      StateDirectory = "steam-app-%i";
      TimeoutStartSec = 3600; # Allow time for updates.
      UMask = "0002"; # Make files group-writable
      User = "steam";
      WorkingDirectory = "~";
    };
  };
}
