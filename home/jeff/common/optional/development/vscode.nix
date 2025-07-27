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

  # VSCode will manage its own settings file after initial creation
  # No need for external dotfiles or symlinks
in
{
  # Create initial VSCode settings file only if it doesn't exist
  # This allows home-manager to set up initial config while letting VSCode write to it normally
  home.activation.createVSCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settingsFile="${config.home.homeDirectory}/.config/Code/User/settings.json"

    # Only create the file if it doesn't exist (first installation)
    if [ ! -f "$settingsFile" ]; then
      echo "Creating initial VSCode settings file..."

      # Create the directory structure if it doesn't exist
      mkdir -p "$(dirname "$settingsFile")"

      # Create the initial settings file
      cat > "$settingsFile" << 'EOF'
    ${builtins.toJSON defaultSettings}
    EOF

      # Ensure the file is writable by the user
      chmod 644 "$settingsFile"
      echo "VSCode settings initialized. VSCode can now modify this file normally."
    else
      echo "VSCode settings file already exists, leaving it unchanged."
    fi
  '';

  # VSCode will manage its own settings file - no symlink needed
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Language support
        ms-python.python
        ms-python.debugpy
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
