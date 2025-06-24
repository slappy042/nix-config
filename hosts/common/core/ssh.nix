{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{

  programs.ssh = lib.optionalAttrs pkgs.stdenv.isLinux {
    startAgent = true;
    enableAskPassword = true;
    askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

    knownHostsFiles = [
      (pkgs.writeText "custom_known_hosts" ''

      '')
    ]
    # ++ lib.optional (!config.hostSpec.isMinimal) (
    #   pkgs.writeText "custom_private_known_hosts" inputs.nix-secrets.networking.ssh.knownHostsFileContents
    # )
    # ++ lib.optional (config.hostSpec.isWork) (
    #   pkgs.writeText "custom_work_known_hosts" inputs.nix-secrets.work.ssh.knownHostsFileContents
    # );
    ;
  };
}
