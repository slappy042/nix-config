{ lib, config, ... }:

{
  # Helper function to register a game service in the JSON registry
  # This creates the ~/services/<id>.json file that the justfile parses
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
      group ? user,
      workingDirectory ? null,
      cleanFilters ? [ ], # List of specific paths to clean for this game
    }:
    let
      serviceJson = builtins.toJSON {
        inherit
          id
          name
          description
          executable
          args
          environment
          ports
          cleanFilters
          ;
        unitName = unitName;
        steamApp = steamApp;
        gameDir = gameDir;
        configFile = configFile;
        logDir = logDir;
        inherit user group;
        workingDirectory = workingDirectory;
      };
    in
    {
      # Use home-manager to create the service registry file
      home-manager.users.${config.hostSpec.username}.home.file."services/${id}.json" = {
        text = serviceJson;
      };
    };

  # Helper function to create a steam user for a game service
  createGameUser =
    {
      username,
      description ? "${username} game server user",
      group ? username,
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

  # Helper function to create systemd tmpfiles rules for game directories and symlinks
  createGameDirectories =
    {
      user,
      group ? user,
      homeDir ? "/home/${user}",
      logDir ? "${homeDir}/logs",
      extraDirs ? [ ],
      gameDir ? null,
      gameSymlink ? null,
    }:
    let
      dirRules = [
        "d ${homeDir} 0750 ${user} ${group} - -"
        "d ${logDir} 0750 ${user} ${group} - -"
      ]
      ++ (map (dir: "d ${dir} 0750 ${user} ${group} - -") extraDirs);
      symlinkRule =
        if gameSymlink != null && gameDir != null then
          [ "L ${gameSymlink} - ${user} ${group} - ${gameDir}" ]
        else
          [ ];
    in
    {
      systemd.tmpfiles.rules = dirRules ++ symlinkRule;
    };
}
