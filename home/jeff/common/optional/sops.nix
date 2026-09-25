# home level sops. see hosts/common/optional/sops.nix for hosts level
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  sopsFolder = (builtins.toString inputs.nix-secrets) + "/sops";
  homeDirectory = config.home.homeDirectory;
  # FIXME(yubikey): move this, u2f sops extraction, and other yubi stuff to be set as yubikey module options
  # so it doesn't doesn't interfere with bootstrapping
  yubikeys = [
    # "maya"
    # "mara"
    # "manu"
    # "mila"
    # "meek"
  ];
  nonYubikeys = [
    "camelot"
    "github_slappy"
    "github_benway"
  ];
  braveUsers = [
    "jhardy042"
    "thehefes042"
  ];
  allSecrets =
    # extract to default pam-u2f authfile location for passwordless sudo. see modules/common/yubikey
    lib.optionalAttrs config.hostSpec.useYubikey {
      "keys/u2f" = {
        sopsFile = "${sopsFolder}/shared.yaml";
        path = "${homeDirectory}/.config/Yubico/u2f_keys";
      };
    }
    // lib.attrsets.mergeAttrsList (
      lib.lists.map (name: {
        "keys/ssh/${name}/private_key" = {
          sopsFile = "${sopsFolder}/shared.yaml";
          path = "${homeDirectory}/.ssh/id_${name}";
        };
        "keys/ssh/${name}/keygrip" = {
          sopsFile = "${sopsFolder}/shared.yaml";
          path = "${homeDirectory}/.ssh/.keygrips/id_${name}_keygrip";
          mode = "0400";
        };
      }) (yubikeys ++ nonYubikeys)
    );
  braveSecrets = lib.attrsets.mergeAttrsList (
    lib.lists.map (user: {
      "keys/brave/${user}/sync-code" = {
        sopsFile = "${sopsFolder}/shared.yaml";
        path = "${homeDirectory}/.config/brave-sync-codes/brave_${user}";
        mode = "0400";
      };
    }) braveUsers
  );
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  sops = {
    # This is the location of the host specific age-key for ta and will to have been extracted to this location via hosts/common/core/sops.nix on the host
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = "${sopsFolder}/${config.hostSpec.hostName}.yaml";
    validateSopsFiles = false;

    # sops-nix's go.mod now requires go >= 1.26, but nixos-25.11's pinned go is still 1.25.x.
    # Build sops-install-secrets with unstable's go until 25.11 catches up.
    # See: https://github.com/Mic92/sops-nix (go.mod bumped in 2bd00bd)
    package = (pkgs.callPackage inputs.sops-nix { }).sops-install-secrets.override {
      buildGoModule = pkgs.buildGoModule.override { go = pkgs.unstable.go; };
    };

    secrets = {
      #placeholder for tokens that I haven't gotten to yet
      #"tokens/foo" = {
      #};
    }
    // allSecrets
    // braveSecrets;
  };
}
