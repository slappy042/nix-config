# Visual Studio Code with extensions

{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  # Get marketplace extensions from input (they should inherit allowUnfree through overlay)
  vscode-marketplace = pkgs.nix-vscode-extensions.vscode-marketplace;
in
{
  programs.vscode = {
    enable = true;
    # profiles.default = {
    #   extensions = with vscode-marketplace; [
    #     # Language support
    #     ms-python.python
    #     ms-vscode.cpptools
    #     # ms-dotnettools.csharp
    #     # golang.go
    #     # rust-lang.rust-analyzer
    #     # bradlc.vscode-tailwindcss
    #     ms-azuretools.vscode-docker

    #     # Nix support
    #     bbenoist.nix
    #     jnoortheen.nix-ide

    #     # Git
    #     eamodio.gitlens
    #     github.vscode-pull-request-github

    #     # Productivity
    #     ms-vscode.hexeditor
    #     # ms-vsliveshare.vsliveshare
    #     esbenp.prettier-vscode
    #     redhat.vscode-yaml
    #     ms-vscode-remote.remote-ssh
    #     # ms-vscode.remote-explorer

    #     # Themes
    #     pkief.material-icon-theme
    #     zhuangtongfa.material-theme

    #     # Additional extensions
    #     johnpapa.vscode-peacock
    #     tomoki1207.pdf
    #     github.copilot

    #   ];
    #   # ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    #   #     # Additional extensions from marketplace
    #   #     {
    #   #     name = "copilot";
    #   #     publisher = "github";
    #   #     version = "1.138.0";
    #   #     sha256 = "sha256-/U1s1ceUm7/qFjjYgJH2QwZQ8l3/Z9XAQX+FY+L6v6g=";
    #   #     }
    #   # ];

    #   userSettings = {
    #     "editor.fontFamily" = "'Fira Code', 'monospace'";
    #     "editor.fontLigatures" = true;
    #     "editor.fontSize" = 14;
    #     "editor.tabSize" = 2;
    #     "editor.insertSpaces" = true;
    #     "editor.formatOnSave" = true;
    #     "files.autoSave" = "afterDelay";
    #     "workbench.colorTheme" = "Material Theme";
    #     "workbench.iconTheme" = "material-icon-theme";
    #   };
    # };
  };
}
