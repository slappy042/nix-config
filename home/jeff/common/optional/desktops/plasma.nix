{ pkgs, inputs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;

    workspace = {
      # Set Klassy as the window decoration theme
      windowDecorations = {
        library = "org.kde.klassy";
        theme = "Klassy";
      };

      # Optional: Set Klassy as the application style
      # theme = "klassy";
    };

    # You can add more plasma-manager configurations here
    # See: https://github.com/nix-community/plasma-manager
  };
}
