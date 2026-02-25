{ pkgs, inputs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;

    workspace = {
      # Set the global theme (look and feel)
      lookAndFeel = "org.kde.klassykitedarkleftpanel.desktop";

      # Set Klassy as the window decoration theme
      windowDecorations = {
        library = "org.kde.klassy";
        theme = "Klassy";
      };
    };

    # You can add more plasma-manager configurations here
    # See: https://github.com/nix-community/plasma-manager
  };
}
