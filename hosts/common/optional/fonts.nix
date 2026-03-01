{ pkgs, ... }:
{
  # System-wide font configuration
  fonts = {
    enableDefaultPackages = true;

    packages = builtins.attrValues {
      inherit (pkgs)
        meslo-lgs-nf
        fira # Fira Sans for regular text
        ;

      inherit (pkgs.nerd-fonts)
        noto
        fira-code
        ;
    };

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "FiraCode Nerd Font" ];
        sansSerif = [ "Fira Sans" ];
      };
    };
  };
}
