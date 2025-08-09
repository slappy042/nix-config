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
          DisplayServer = "wayland";
          LogLevel = "debug";
        };
      };
    };
  };

  # Use Wayland session by default (Plasma 6)
  services.displayManager.defaultSession = "plasma";

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
  ];

  # Wayland-friendly defaults for apps (keep minimal) + force KWin to AMD GPU for user session
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron/Chromium apps use Wayland
    MOZ_ENABLE_WAYLAND = "1"; # Firefox on Wayland
    KWIN_DRM_DEVICES = "/dev/dri/kwin-amdgpu"; # Stable symlink to AMD GPU
  };

  # Ensure SDDM can access DRM/render nodes
  users.users.sddm.extraGroups = [
    "video"
    "render"
  ];

}
