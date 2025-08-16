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
      "hosts/common/optional/services/bluetooth.nix" # Bluetooth
      "hosts/common/optional/services/openssh.nix" # allow remote SSH access
      "hosts/common/optional/services/printing.nix" # CUPS
      "hosts/common/optional/services/tailscale.nix" # Tailscale
      "hosts/common/optional/audio.nix" # pipewire and cli controls
      # "hosts/common/optional/libvirt.nix" # vm tools
      "hosts/common/optional/gaming/minecraft.nix" # Minecraft launcher
      "hosts/common/optional/gaming/steam.nix" # steam, gamescope, gamemode, and related hardware
      # "hosts/common/optional/hyprland.nix" # window manager
      "hosts/common/optional/kde.nix" # KDE
      # "hosts/common/optional/msmtp.nix" # for sending email notifications
      # "hosts/common/optional/nvtop.nix" # GPU monitor (not available in home-manager)
      # "hosts/common/optional/obsidian.nix" # wiki
      # "hosts/common/optional/plymouth.nix" # fancy boot screen
      # "hosts/common/optional/protonvpn.nix" # vpn
      # "hosts/common/optional/scanning.nix" # SANE and simple-scan
      "hosts/common/optional/smbclient.nix" # for mounting samba shares
      # "hosts/common/optional/thunar.nix" # file manager
      "hosts/common/optional/vlc.nix" # media player
      # "hosts/common/optional/wayland.nix" # wayland components and pkgs not available in home-manager
      # "hosts/common/optional/yubikey.nix" # yubikey related packages and configs
      # "hosts/common/optional/zsa-keeb.nix" # Moonlander keeb flashing stuff
    ])

    #
    # ========== Host Specific Configs ==========
    #
    ./touchpad.nix # touchpad configuration
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

  # Fix MST DSC timeout issues with this AMD chipset during multi-monitor boot
  boot.kernelParams = [
    "amdgpu.modeset=1" # Enable kernel mode setting
    "drm.mst_mgr_timeout=10000" # Increase MST timeout from 3s to 10s
    "amdgpu.dc=1" # Ensure Display Core is enabled
  ];

  # Enable Bluetooth kernel modules
  boot.kernelModules = [
    "kvm-amd"
    "btusb" # USB Bluetooth adapters
    "bluetooth" # Core Bluetooth stack
    "btrtl" # Realtek Bluetooth driver
    "btintel" # Intel Bluetooth driver (in case of mixed hardware)
    "btbcm" # Broadcom Bluetooth driver
    # Touchpad and input device modules
    "i2c_hid" # I2C HID devices (common for modern touchpads)
    "i2c_hid_acpi" # ACPI-based I2C HID devices
    "hid_multitouch" # Multitouch HID devices
  ];

  hardware.graphics.enable = true;
  #hardware.graphics.package = lib.mkForce pkgs.unstable.mesa.drivers;
  hardware.amdgpu.initrd.enable = true; # load amdgpu kernelModules in stage 1.
  hardware.amdgpu.opencl.enable = true; # OpenCL support - general compute API for gpu
  hardware.amdgpu.amdvlk.enable = true; # additional, alternative drivers

  # Fix display manager startup timing for MST DSC issues
  systemd.services.display-manager = {
    after = [ "systemd-udev-settle.service" ];
    wants = [ "systemd-udev-settle.service" ];
    serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
  };

  # Removed custom amdgpu kernel params & udev/systemd overrides for vanilla Wayland/Plasma
  # (Previously: boot.kernelParams, services.udev.extraRules creating kwin-amdgpu symlink,
  #  systemd.services.display-manager.* overrides & KWIN_* env vars)

  # Generation label (shown by supported bootloaders)
  system.nixos.label =
    let
      lbl = builtins.getEnv "GENERATION_LABEL";
    in
    if lbl != "" then lbl else "z13flow";

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
