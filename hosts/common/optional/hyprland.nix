{ inputs, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
  };

  environment.systemPackages = [
    inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
