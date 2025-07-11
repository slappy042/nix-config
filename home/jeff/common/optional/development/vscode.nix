# Visual Studio Code with extensions

{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  configDirName =
    {
      "vscode" = "Code";
      "vscode-insiders" = "Code - Insiders";
      "vscodium" = "VSCodium";
    }
    .${config.programs.vscode.package.pname};

  # Default settings to initialize the external settings file
  defaultSettings = {
    # Settings Sync configuration
    "settingsSync.account" = "slappy042";
    "settingsSync.enable" = true;
    "settingsSync.ignoredSettings" = [
      "git.path" # Environment-specific, managed by Nix
    ];
    "settingsSync.ignoredExtensions" = [ ];
    "settingsSync.keybindingsPerPlatform" = false;

    # Environment-specific settings (managed by Nix, not synced)
    "git.path" = "${pkgs.git}/bin/git";
    "git.useConfigOnly" = true;

    # Basic editor settings
    "editor.fontFamily" = "'Fira Code', 'JetBrains Mono', 'Cascadia Code', monospace";
    "editor.fontSize" = 14;
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "files.insertFinalNewline" = true;
    "workbench.startupEditor" = "none";
  };

  settingsFile = "${config.home.homeDirectory}/dev/dotfiles/nix/config/settings.json";
in
{
  # Ensure the dotfiles directory exists
  home.file."dev/dotfiles/nix/config/.keep".text = "";

  # Create the settings file if it doesn't exist
  home.file."dev/dotfiles/nix/config/settings.json" = {
    text = builtins.toJSON defaultSettings;
    # Only create if file doesn't exist (won't overwrite existing file)
    force = false;
  };

  # Symlink VSCode settings to the external file
  xdg.configFile."${configDirName}/User/settings.json".source = lib.mkForce (
    config.lib.file.mkOutOfStoreSymlink settingsFile
  );
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Language support
        ms-python.python
        ms-vscode.cpptools
        # ms-dotnettools.csharp
        # golang.go
        # rust-lang.rust-analyzer
        # bradlc.vscode-tailwindcss
        ms-azuretools.vscode-docker

        # Nix support
        bbenoist.nix
        jnoortheen.nix-ide

        # Git
        eamodio.gitlens
        github.vscode-pull-request-github
        github.github-vscode-theme

        # Productivity
        ms-vscode.hexeditor
        # ms-vsliveshare.vsliveshare
        esbenp.prettier-vscode
        redhat.vscode-yaml
        ms-vscode-remote.remote-ssh
        # ms-vscode.remote-explorer

        # Themes
        pkief.material-icon-theme
        zhuangtongfa.material-theme

        # Additional extensions
        johnpapa.vscode-peacock
        tomoki1207.pdf
        github.copilot

      ];
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
  };
}
