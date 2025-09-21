{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.environment;
in

{

  options = {
    environment.binbash = lib.mkOption {
      default = "${pkgs.bash}/bin/bash";
      defaultText = lib.literalExpression ''"''${pkgs.bash}/bin/bash"'';
      example = lib.literalExpression ''"''${pkgs.bashInteractive}/bin/bash"'';
      type = lib.types.path;
      description = ''
        The bash executable that is linked system-wide to
        `/bin/bash`. This provides compatibility for scripts
        that expect bash to be available at this standard location.
      '';
    };
  };

  config = {

    system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
      # Create the required /bin/bash symlink for compatibility
      # with scripts that expect bash at this standard location.
      mkdir -p /bin
      chmod 0755 /bin
      ln -sfn "${cfg.binbash}" /bin/.bash.tmp
      mv /bin/.bash.tmp /bin/bash # atomically replace /bin/bash
    '';

  };

}
