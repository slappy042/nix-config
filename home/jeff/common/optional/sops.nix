# home level sops. see hosts/common/optional/sops.nix for hosts level
{
  inputs,
  config,
  lib,
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
        "keys/ssh/${name}" = {
          sopsFile = "${sopsFolder}/shared.yaml";
          path = "${homeDirectory}/.ssh/id_${name}";
        };
      }) (yubikeys ++ nonYubikeys)
    );
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  sops = {
    # This is the location of the host specific age-key for ta and will to have been extracted to this location via hosts/common/core/sops.nix on the host
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = "${sopsFolder}/${config.hostSpec.hostName}.yaml";
    validateSopsFiles = false;

    secrets = {
      #placeholder for tokens that I haven't gotten to yet
      #"tokens/foo" = {
      #};

      # Brave sync code
      "keys/brave/jeff/sync-code" = {
        sopsFile = "${sopsFolder}/shared.yaml";
        path = "${homeDirectory}/.config/brave-sync-code";
        mode = "0400";
      };
    } // allSecrets;
  };
}
