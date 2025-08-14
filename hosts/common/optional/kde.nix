{
  pkgs,
  config,
  lib,
  ...
}:
{

  services = {
    xserver = {
      enable = true;
    };
    desktopManager.plasma6.enable = true;

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      settings = {
        General = {
          LogLevel = "debug";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
    kdePackages.ark # Archive manager
    kdePackages.kate # Advanced text editor
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
    kdePackages.kcolorchooser # A small utility to select a color
    kdePackages.kolourpaint # Easy-to-use paint program
    kdePackages.kmix # Audio mixer
    kdePackages.ksystemlog # KDE SystemLog Application
    kdePackages.plasma-nm # NetworkManager integration
    kdePackages.sddm-kcm # Configuration module for SDDM
    kdiff3 # Compares and merges 2 or 3 files or directories
    kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
    kdePackages.partitionmanager # Optional Manage the disk devices, partitions and file systems on your computer
    hardinfo2 # System information and benchmarks for Linux systems
    haruna # Open source video player built with Qt/QML and libmpv
    wayland-utils # Wayland utilities
    wl-clipboard # Command-line copy/paste utilities for Wayland

    libsecret
    keepass

    # Input device management tools
    libinput # Input device management
    xorg.xinput # X input device configuration tool
    kdePackages.kdebugsettings # runtime GUI to toggle Qt logging categories

    # Wrapper script ensuring correct arg splitting for Plasma Wayland
    (pkgs.writeShellScriptBin "plasma-wayland-wrapper" ''
      exec ${pkgs.kdePackages.plasma-workspace}/libexec/plasma-dbus-run-session-if-needed \
           ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
    '')
  ];

  # Keep only generic Wayland-friendly app vars; drop KWIN overrides
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    # KWin / Plasma debug categories. Adjust as needed (see kdebugsettings).
    QT_LOGGING_RULES = lib.concatStringsSep ";" [
      "kwin.*=true"
      "kwin_wayland.*=true"
      "kwin_platform_wayland.*=true"
      "kwin_scene.*=true"
      "kwin_libinput.*=true"
      "kwin_core.*=true"
      # Comment out noisy categories if log too large.
    ];
  };

  # Provide custom Wayland session desktop file via sessionPackages
  # workaround for the exec issue in https://github.com/NixOS/nixpkgs/issues/355533
  services.displayManager.sessionPackages =
    let
      plasmaFixedSession =
        (pkgs.writeTextDir "share/wayland-sessions/plasma-fixed.desktop" ''
          [Desktop Entry]
          Type=Application
          Name=Plasma (Wayland Fixed)
          Comment=KDE Plasma (Wayland) via wrapper to avoid SDDM arg concatenation bug
          Exec=plasma-wayland-wrapper
          TryExec=${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland
          DesktopNames=KDE
          X-GDM-SessionRegisters=true
        '').overrideAttrs
          (oldAttrs: {
            passthru = (oldAttrs.passthru or { }) // {
              providedSessions = [ "plasma-fixed" ];
            };
          });
    in
    [ plasmaFixedSession ];

  # Use custom wrapper Wayland session by default
  services.displayManager.defaultSession = "plasma-fixed";

  # Ensure SDDM can access DRM/render/input nodes
  users.users.sddm.extraGroups = [
    "video"
    "render"
    "input"
  ];

}
