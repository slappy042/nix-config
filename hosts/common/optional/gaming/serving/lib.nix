{ lib, ... }:

{
  # Helper function to register a game service in the JSON registry
  # This creates the /etc/gameserver/services/<id>.json file that the justfile parses
  registerGameService =
    {
      id,
      name,
      description,
      serviceName,
      steamApp ? null,
      gameDir ? null,
      ports ? [ ],
      configFile ? null,
      logDir ? null,
      user ? null,
      group ? "game",
    }:
    {
      environment.etc."gameserver/services/${id}.json" = {
        text = builtins.toJSON {
          inherit id name description;
          service_name = serviceName;
          steam_app = steamApp;
          game_dir = gameDir;
          inherit ports;
          config_file = configFile;
          log_dir = logDir;
          inherit user group;
        };
        mode = "0644";
      };
    };

  # Helper function to create a steam user for a game service
  createGameUser =
    {
      username,
      description ? "${username} game server user",
      group ? "game",
      extraGroups ? [ ],
      homeDir ? "/home/${username}",
    }:
    {
      users.users.${username} = {
        isSystemUser = true;
        inherit description group;
        extraGroups = extraGroups ++ [ group ];
        home = homeDir;
        createHome = true;
      };
    };

  # Helper function to create systemd tmpfiles rules for game directories
  createGameDirectories =
    {
      user,
      group ? "game",
      homeDir ? "/home/${user}",
      logDir ? "${homeDir}/logs",
      extraDirs ? [ ],
    }:
    {
      systemd.tmpfiles.rules = [
        "d ${homeDir} 0750 ${user} ${group} - -"
        "d ${logDir} 0750 ${user} ${group} - -"
      ]
      ++ (map (dir: "d ${dir} 0750 ${user} ${group} - -") extraDirs);
    };
}
