# Visual Studio Code with extensions

{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    extensions =
      with pkgs.vscode-extensions;
      [
        # Language support
        ms-python.python
        ms-vscode.cpptools
        ms-dotnettools.csharp
        golang.go
        rust-lang.rust-analyzer
        bradlc.vscode-tailwindcss
        ms-vscode.vscode-typescript-next

        # Nix support
        bbenoist.nix
        jnoortheen.nix-ide

        # Git
        eamodio.gitlens
        github.vscode-pull-request-github

        # Productivity
        ms-vscode.hexeditor
        ms-vsliveshare.vsliveshare
        esbenp.prettier-vscode
        ms-vscode.vscode-json
        redhat.vscode-yaml

        # Themes
        pkief.material-icon-theme
        zhuangtongfa.material-theme
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # Additional extensions from marketplace
        {
          name = "copilot";
          publisher = "github";
          version = "1.138.0";
          sha256 = "sha256-/U1s1ceUm7/qFjjYgJH2QwZQ8l3/Z9XAQX+FY+L6v6g=";
        }
      ];

    userSettings = {
      "editor.fontFamily" = "'Fira Code', 'monospace'";
      "editor.fontLigatures" = true;
      "editor.fontSize" = 14;
      "editor.tabSize" = 2;
      "editor.insertSpaces" = true;
      "editor.formatOnSave" = true;
      "files.autoSave" = "afterDelay";
      "workbench.colorTheme" = "Material Theme";
      "workbench.iconTheme" = "material-icon-theme";
    };
  };
}
