{ pkgs, ... }:
{
  # This is a fix to enable VSCode to successfully remote SSH on a client to a NixOS host
  # https://wiki.nixos.org/wiki/Visual_Studio_Code # Remote_SSH
  programs.nix-ld.enable = true;
  programs.nix-ld.package = pkgs.nix-ld-rs;
}
