{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # Only enable if gameserver-manager input is available
  config = lib.mkIf (inputs ? gameserver-manager && inputs.gameserver-manager ? nixosModules) {

    # Import the NixOS module
    imports = [ inputs.gameserver-manager.nixosModules.default ];

    # Configure the service
    services.gameserver-manager = {
      enable = lib.mkDefault true;
      steamcmd.enable = lib.mkDefault true;
      openFirewall = lib.mkDefault false; # Set to false - feature doesn't work yet

      # Use your primary user for personal usage
      # NOTE: When user != "gameserver", paths automatically default to home directory
      user = lib.mkDefault config.hostSpec.username; # "jeff"
      group = lib.mkDefault "users";

      # Paths are auto-detected based on user:
      # - user = "gameserver" → system paths (/var/lib/gameserver-manager/*)
      # - user = anything else → home paths (~/games, ~/services)
      # You can override these if needed:
      # gamesDir = lib.mkDefault "${config.users.users.${config.hostSpec.username}.home}/games";
      # servicesDir = lib.mkDefault "${config.users.users.${config.hostSpec.username}.home}/services";
    };

    # Ensure the gameserver-manager package is available in environment
    environment.systemPackages =
      with pkgs;
      [
        # Package will be available via overlay
      ]
      ++ lib.optional (builtins.hasAttr "gameserver-manager" pkgs) pkgs.gameserver-manager;

    # Optional: Add some helpful aliases for the gameserver user
    programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
      gsm = "gameserver";
      gs-status = "gameserver status";
      gs-list = "gameserver list";
    };

    programs.bash.shellAliases = lib.mkIf config.programs.bash.enable {
      gsm = "gameserver";
      gs-status = "gameserver status";
      gs-list = "gameserver list";
    };
  };
}
