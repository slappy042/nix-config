{ pkgs, ... }:
{
  # Font packages are now installed system-wide via hosts/common/optional/fonts.nix
  # Keep fontconfig enabled for user-level font configuration
  fonts.fontconfig.enable = true;
}
