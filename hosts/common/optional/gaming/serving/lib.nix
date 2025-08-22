{ lib, ... }:

{
  # Helper function to register a game service in the JSON registry
  # This creates the /etc/gameserver/services/<id>.json file that the justfile parses
  registerGameService =
    {
      id,
      name,
      description,
      unitName ? "${id}-server", # systemd-run unit name
      steamApp ? null,
      gameDir ? null,
      executable ? null,
      args ? [ ],
      environment ? { },
      ports ? [ ],
      configFile ? null,
      logDir ? null,
      user ? null,
      group ? "game",
      workingDirectory ? null,
    }:
    {
      environment.etc."gameserver/services/${id}.json" = {
        text = builtins.toJSON {
          inherit
            id
            name
            description
            executable
            args
            environment
            ports
            ;
          unit_name = unitName;
          steam_app = steamApp;
          game_dir = gameDir;
          config_file = configFile;
          log_dir = logDir;
          inherit user group;
          working_directory = workingDirectory;
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
