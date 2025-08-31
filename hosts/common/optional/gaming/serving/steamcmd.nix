# steamcmd.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Add steamcmd to system packages for direct execution
  environment.systemPackages = with pkgs; [
    steamcmd # Direct steamcmd execution in justfile
  ];

  # Configure primary user's home directory with home-manager
  home-manager.users.${config.hostSpec.username} = {
    home.file."README-steamcmd.md" = {
      source = ./docs/steamcmd.md;
    };
  };
}
