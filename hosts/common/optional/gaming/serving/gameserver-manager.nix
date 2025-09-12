{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # Import the NixOS module from gameserver-manager flake
  imports = [
    inputs.gameserver-manager.nixosModules.default
  ];

  # Configure the service
  services.gameserver-manager = {
    enable = lib.mkDefault true;
    steamcmd.enable = lib.mkDefault true;
  };

  # Manual firewall configuration required since openFirewall doesn't work yet
  # Add your game ports to the host-specific config like this:
  # networking.firewall = {
  #   allowedTCPPorts = [ 26900 26901 26902 25565 ];  # Your game ports
  #   allowedUDPPorts = [ 26900 26901 26902 25565 ];  # Usually same as TCP
  # };

  # Optional: Add some helpful aliases for the gameserver user
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    gsm = "gameserver-manager";
    gs-status = "gameserver-manager status";
    gs-list = "gameserver-manager list";
  };
}
