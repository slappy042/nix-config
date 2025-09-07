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
      openFirewall = lib.mkDefault true;

      # Customize directories (can be overridden in host configs)
      gamesDir = lib.mkDefault "/srv/gameserver/games";
      servicesDir = lib.mkDefault "/etc/gameserver/services";
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
      gsm = "gameserver-manager";
      gs-status = "gameserver-manager status";
      gs-list = "gameserver-manager list";
    };

    programs.bash.shellAliases = lib.mkIf config.programs.bash.enable {
      gsm = "gameserver-manager";
      gs-status = "gameserver-manager status";
      gs-list = "gameserver-manager list";
    };
  };
}
