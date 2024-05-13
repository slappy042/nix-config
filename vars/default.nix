{ inputs, lib }:
{
  username = "jeff";
  networking = import ./networking.nix { inherit lib; };
  persistFolder = "/persist";
  isMinimal = false; # Used to indicate nixos-installer build
}
