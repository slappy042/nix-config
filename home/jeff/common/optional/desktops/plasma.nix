{ pkgs, inputs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;

    workspace = {
      # Set the global theme (look and feel). It also sets the Klassy window
      # decoration, so windowDecorations isn't set separately (plasma-manager
      # warns when both are set).
      lookAndFeel = "org.kde.klassykitedarkleftpanel.desktop";
    };

    # You can add more plasma-manager configurations here
    # See: https://github.com/nix-community/plasma-manager
  };
}
