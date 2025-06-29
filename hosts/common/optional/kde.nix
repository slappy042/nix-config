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
      # wayland.enable = true;
      # settings.General.DisplayServer = "wayland";
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

    keepassxc
  ];

  environment.sessionVariables = {
    # "NIXOS_OZONE_WL" = "1"; # for ozone-based and electron apps to run on wayland
    # "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
    # "MOZ_WEBRENDER" = "1"; # for firefox to run on wayland
    # "XDG_SESSION_TYPE" = "wayland";
    # "WLR_NO_HARDWARE_CURSORS" = "1";
    # "WLR_RENDERER_ALLOW_SOFTWARE" = "1";
    # "QT_QPA_PLATFORM" = "wayland";
    # "HYPRCURSOR_THEME" = "rose-pine-hyprcursor"; # this will be better than default for now
  };

  # Force X11
  services.displayManager.sddm.wayland.enable = false;
  services.xserver.displayManager.defaultSession = "plasmax11";

  # Disable Wayland for KDE to avoid AMD GPU issues
  environment.sessionVariables = {
    # Force Qt/KDE to use X11
    QT_QPA_PLATFORM = "xcb";
    # Disable Wayland session
    NIXOS_OZONE_WL = "0";
    XDG_SESSION_TYPE = "x11"; # Force X11 session
  };

}
