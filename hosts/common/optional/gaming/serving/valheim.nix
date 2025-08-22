# valheim.nix
# https://kevincox.ca/2022/12/09/valheim-server-nixos-v2/
# JEFF: NOT USED BY ME BECAUSE WE'RE NOT PLAYING VALHEIM
# BUT THIS MIGHT SERVE AS A TEMPLATE FOR OTHER GAMES

{
  config,
  pkgs,
  lib,
  utils,
  ...
}:
let
  # Set to {id}-{branch}-{password} for betas.
  steam-app = "896660";
in
{
  users.users.valheim = {
    isSystemUser = true;
    # Valheim puts save data in the home directory.
    home = "/home/valheim";
    createHome = true;
    homeMode = "750";
    group = "game";
  };

  # No need for a separate valheim group - we use the shared game group

  systemd.services.valheim = {
    wantedBy = [ "multi-user.target" ];

    # Install the game before launching.
    wants = [ "steam@${steam-app}.service" ];
    after = [ "steam@${steam-app}.service" ];

    serviceConfig = {
      ExecStart = utils.escapeSystemdExecArgs [
        "/var/lib/steam-app-${steam-app}/valheim_server.x86_64"
        "-nographics"
        "-batchmode"
        # "-crossplay" # This is broken because it looks for "party" shared library in the wrong path.
        "-savedir"
        "/var/lib/valheim/save"
        "-name"
        "YOUR SERVER NAME"
        "-port"
        "2456"
        "-world"
        "Dedicated"
        "-password"
        "YOUR PASSWORD HERE!!!"
        "-public"
        "0" # Valheim now supports favourite servers in-game which I am using instead of listing in the public registry.
        "-backups"
        "0" # I take my own backups, if you don't you can remove this to use the built-in basic rotation system.
      ];
      Nice = "-5";
      PrivateTmp = true;
      Restart = "always";
      UMask = "0002"; # Make files group-writable
      User = "valheim";
      WorkingDirectory = "~";
    };
    environment = {
      # linux64 directory is required by Valheim.
      LD_LIBRARY_PATH = "/var/lib/steam-app-${steam-app}/linux64:${pkgs.glibc}/lib";
      SteamAppId = "892970";
    };
  };

  # This is my custom backup machinery. Substitute your own 🙂
  kevincox.backup.valheim = {
    paths = [
      "/home/valheim/.local/share/7DaysToDie/Saves/"
    ];
  };
}
