#############################################################
#
#  Z13 Flow
#  NixOS on Asus Z13 Flow (2025) Max+ AI 395
#
###############################################################

{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    #
    # ========== Hardware ==========
    #
    ./hardware-configuration.nix
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    #
    # ========== Disk Layout ==========
    #
    inputs.disko.nixosModules.disko
    (lib.custom.relativeToRoot "hosts/common/disks/btrfs-luks-impermanence-disk.nix")
    {
      _module.args = {
        disk = "/dev/nvme0n1";
        withSwap = true;
        swapSize = 8;
      };
    }
    (map lib.custom.relativeToRoot [
      #
      # ========== Required Configs ==========
      #
      "hosts/common/core"

      #
      # ========== Optional Configs ==========
      #
      # "hosts/common/optional/services/greetd.nix" # display manager
      "hosts/common/optional/services/openssh.nix" # allow remote SSH access
      "hosts/common/optional/services/printing.nix" # CUPS
      "hosts/common/optional/audio.nix" # pipewire and cli controls
      # "hosts/common/optional/libvirt.nix" # vm tools
      "hosts/common/optional/gaming.nix" # steam, gamescope, gamemode, and related hardware
      # "hosts/common/optional/hyprland.nix" # window manager
      "hosts/common/optional/kde.nix" # KDE
      # "hosts/common/optional/msmtp.nix" # for sending email notifications
      # "hosts/common/optional/nvtop.nix" # GPU monitor (not available in home-manager)
      # "hosts/common/optional/obsidian.nix" # wiki
      "hosts/common/optional/plymouth.nix" # fancy boot screen
      # "hosts/common/optional/protonvpn.nix" # vpn
      # "hosts/common/optional/scanning.nix" # SANE and simple-scan
      "hosts/common/optional/smbclient.nix" # for mounting samba shares
      # "hosts/common/optional/thunar.nix" # file manager
      "hosts/common/optional/vlc.nix" # media player
      # "hosts/common/optional/wayland.nix" # wayland components and pkgs not available in home-manager
      # "hosts/common/optional/yubikey.nix" # yubikey related packages and configs
      # "hosts/common/optional/zsa-keeb.nix" # Moonlander keeb flashing stuff
    ])
  ];

  #
  # ========== Host Specification ==========
  #

  hostSpec = {
    hostName = "z13flow";
    persistFolder = "/persist"; # added for "completion" because of the disko spec that was used even though impermanence isn't actually enabled here yet.
  };

  networking = {
    networkmanager.enable = true;
    enableIPv6 = false;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };
  boot.initrd = {
    systemd.enable = true;
    # This mostly mirrors what is generated on qemu from nixos-generate-config in hardware-configuration.nix
    kernelModules = [
      # "xhci_pci"
      # "ahci"
      # "usbhid"
      # "usb_storage"
      # "sd_mod"
      "amdgpu" # AMD GPU driver
      "nvme"
      "nvme_core" # Core NVMe support
      "xhci_pci"
      "thunderbolt"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
  };

  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;
  hardware.graphics.enable = true;
  #hardware.graphics.package = lib.mkForce pkgs.unstable.mesa.drivers;
  hardware.amdgpu.initrd.enable = true; # load amdgpu kernelModules in stage 1.
  hardware.amdgpu.opencl.enable = true; # OpenCL support - general compute API for gpu
  hardware.amdgpu.amdvlk.enable = true; # additional, alternative drivers

  # Disable AMD GPU runtime power management (fixes SDDM context creation issues)
  boot.kernelParams = [
    "amdgpu.runpm=0" # Disable runtime power management (can cause issues with SDDM)
    "amdgpu.dc=1" # Enable Display Core
    "amdgpu.dpm=1" # Enable Dynamic Power Management
  ];

  # Force X11 for SDDM to avoid Wayland/AMD GPU context issues
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false; # Disable Wayland, use X11
  };

  # Force KDE/Plasma to use X11 instead of Wayland
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasmax11";

  # Disable Wayland for KDE to avoid AMD GPU issues
  environment.sessionVariables = {
    # Force Qt/KDE to use X11
    QT_QPA_PLATFORM = "xcb";
    # Disable Wayland session
    NIXOS_OZONE_WL = "0";
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
