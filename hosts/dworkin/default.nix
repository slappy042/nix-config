#############################################################
#
#  Dworkin - Dev Lab
#  NixOS running on VirtualBox VM
#
###############################################################

{ inputs, configLib, ... }: {
  imports = [
    #################### Disko Spec ####################
    inputs.disko.nixosModules.disko
    (configLib.relativeToRoot "hosts/common/disks/std-disk-config.nix")

    #################### Hardware Modules ####################
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    #################### Required Configs ####################
    ./hardware-configuration.nix
    (configLib.relativeToRoot "hosts/common/core")

    #################### Host-specific Optional Configs ####################
    (configLib.relativeToRoot "hosts/common/optional/services/openssh.nix")

    #################### Users to Create ####################
   (configLib.relativeToRoot "hosts/common/users/jeff")

  ];

  networking = {
    hostName = "dworkin";
    # networkmanager.enable = true;
    enableIPv6 = false;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };

  # VirtualBox settings for Hyprland to display correctly
  # environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  # environment.sessionVariables.WLR_RENDERER_ALLOW_SOFTWARE = "1";

  # Fix to enable VSCode to successfully remote SSH on a client to a NixOS host
  # https://nixos.wiki/wiki/Visual_Studio_Code # Remote_SSH
  programs.nix-ld.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
