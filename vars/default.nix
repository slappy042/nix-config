{ inputs, lib }:
{
  username = "jeff";
  networking = import ./networking.nix { inherit lib; };
  persistFolder = "/persist";
  isMinimal = false; # Used to indicate nixos-installer build

  handle = "slappy042";
  gitEmail = "75365007+slappy042@users.noreply.github.com";
}
