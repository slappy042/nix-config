#
# This file defines overlays/custom modifications to upstream packages
#

{ inputs, ... }:

let
  # Adds my custom packages
  # FIXME: Add per-system packages
  additions =
    final: prev:
    (prev.lib.packagesFromDirectoryRecursive {
      callPackage = prev.lib.callPackageWith final;
      directory = ../pkgs/common;
    });

  # NOTE: must be optionalAttrs, not mkIf. mkIf adds `_type`/`content` attrs to pkgs, which makes
  # the module system treat the whole package set as an (empty) mkIf wherever pkgs is passed as a value
  linuxModifications = _final: prev: prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux { };

  modifications = final: prev: {
    # FIXME: remove once nixpkgs fixes the src. download.mersenne.ca now redirects to a Google Drive
    # virus-scan page instead of the zip; the official mersenne.org mirror serves the same file
    mprime = prev.mprime.overrideAttrs (old: {
      src = prev.fetchzip {
        url = "https://www.mersenne.org/download/software/v31/31.04/p95v${
          prev.lib.replaceStrings [ "." ] [ "" ] old.version
        }.source.zip";
        hash = "sha256-W8ic709bgm9KbVxe1fvIEC8J8LrwwMfAajX1bKhv6EM=";
        stripRoot = false;
      };
    });

    # example = prev.example.overrideAttrs (oldAttrs: let ... in {
    # ...
    # });
    #    flameshot = prev.flameshot.overrideAttrs {
    #      cmakeFlags = [
    #        (prev.lib.cmakeBool "USE_WAYLAND_GRIM" true)
    #        (prev.lib.cmakeBool "USE_WAYLAND_CLIPBOARD" true)
    #      ];
    #    };
  };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      #      overlays = [
      #     ];
    };
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      #      overlays = [
      #     ];
    };
  };

in
{
  default =
    final: prev:

    (additions final prev)
    // (modifications final prev)
    // (linuxModifications final prev)
    // (stable-packages final prev)
    // (unstable-packages final prev);
}
