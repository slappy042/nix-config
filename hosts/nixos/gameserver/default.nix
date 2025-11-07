#############################################################
#
#  GameServer - serve games
#  NixOS running on Proxmox VM
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

    #
    # ========== Disk Layout ==========
    #
    inputs.disko.nixosModules.disko
    (lib.custom.relativeToRoot "hosts/common/disks/btrfs-impermanence-disk.nix")
    {
      _module.args = {
        disk = "/dev/vda";
        withSwap = false;
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
      "hosts/common/optional/smbclient.nix"
      "hosts/common/optional/gaming/serving/default.nix"
      "hosts/common/optional/gaming/serving/gameserver-manager.nix"
    ])
  ];

  #
  # ========== Host Specification ==========
  #

  hostSpec = {
    hostName = "gameserver";
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
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "usbhid"
      "sr_mod"
      "virtio_blk"
    ];
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
