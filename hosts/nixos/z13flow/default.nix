#############################################################
#
#  Nixxy1
#  NixOS on Lenovo Tiny 910q
#
###############################################################

{
  inputs,
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
    inputs.hardware.nixosModules.common-pc-ssd

    #
    # ========== Disk Layout ==========
    #
    inputs.disko.nixosModules.disko
    (lib.custom.relativeToRoot "hosts/common/disks/btrfs-disk.nix")
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
      "hosts/common/optional/services/greetd.nix" # display manager
      "hosts/common/optional/services/openssh.nix" # allow remote SSH access
      "hosts/common/optional/services/printing.nix" # CUPS
      "hosts/common/optional/audio.nix" # pipewire and cli controls
      "hosts/common/optional/libvirt.nix" # vm tools
      "hosts/common/optional/gaming.nix" # steam, gamescope, gamemode, and related hardware
      "hosts/common/optional/hyprland.nix" # window manager
      # "hosts/common/optional/msmtp.nix" # for sending email notifications
      # "hosts/common/optional/nvtop.nix" # GPU monitor (not available in home-manager)
      # "hosts/common/optional/obsidian.nix" # wiki
      "hosts/common/optional/plymouth.nix" # fancy boot screen
      # "hosts/common/optional/protonvpn.nix" # vpn
      "hosts/common/optional/scanning.nix" # SANE and simple-scan
      "hosts/common/optional/smbclient.nix" # for mounting samba shares
      # "hosts/common/optional/thunar.nix" # file manager
      "hosts/common/optional/vlc.nix" # media player
      "hosts/common/optional/wayland.nix" # wayland components and pkgs not available in home-manager
      # "hosts/common/optional/yubikey.nix" # yubikey related packages and configs
      # "hosts/common/optional/zsa-keeb.nix" # Moonlander keeb flashing stuff
    ])
  ];

  #
  # ========== Host Specification ==========
  #

  hostSpec = {
    hostName = "z13flow";
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
    # kernelModules = [
    #   "xhci_pci"
    #   "ahci"
    #   "usbhid"
    #   "usb_storage"
    #   "sd_mod"
    # ];
  };

  # This is a fix to enable VSCode to successfully remote SSH on a client to a NixOS host
  # https://wiki.nixos.org/wiki/Visual_Studio_Code # Remote_SSH
  programs.nix-ld.enable = true;
  programs.nix-ld.package = pkgs.nix-ld-rs;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
