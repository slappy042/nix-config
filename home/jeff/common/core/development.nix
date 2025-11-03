# Development utilities I want across all systems
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshFolder = "${config.home.homeDirectory}/.ssh";
  publicKey =
    if config.hostSpec.useYubikey then
      "${sshFolder}/id_yubikey.pub"
    else
      "${sshFolder}/id_github_slappy.pub";
  gamingGitEmail = config.hostSpec.github.gaming.email;
  gamingGitName = config.hostSpec.github.gaming.name;
  gamingGitConfig = "${config.home.homeDirectory}/.config/git/gitconfig.gaming";
  stdGitEmail = config.hostSpec.github.std.email;
  stdGitName = config.hostSpec.github.std.name;
  stdGitConfig = "${config.home.homeDirectory}/.config/git/gitconfig.std";
in
{
  home.packages = lib.flatten [
    (builtins.attrValues {
      inherit (pkgs)
        # Development
        direnv
        delta # diffing
        # act # github workflow runner
        # gh # github cli
        # glab # gitlab cli
        yq-go # Parser for Yaml and Toml Files, that mirrors jq

        # nix
        nixpkgs-review
        nixfmt-rfc-style

        # networking
        nmap

        # Diffing
        difftastic

        # serial debugging
        screen

        # Standard man pages for linux API
        man-pages
        man-pages-posix

        # python
        uv
        ;
    })

    #    (lib.optionals pkgs.stdenv.isLinux (
    #      builtins.attrValues {
    #        inherit (pkgs)
    #          gdb
    #          pwndbg
    #          ;
    #      }
    #    ))
  ];

  #NOTE: Already enabled earlier, this is just extra config
  programs.git = {
    userName = stdGitName;
    userEmail = stdGitEmail;

    # Enforce SSH to leverage yubikey
    extraConfig = {

      # FIXME(git): better place for this?
      save.directory = "${config.home.homeDirectory}/sync/obsidian-vault-01/wiki";

      log.showSignature = "true";
      init.defaultBranch = "main";

      # Don't warn on empty git add calls. Because of "git re-commit" automation
      advice.addEmptyPathspec = false;

      url = {
        "ssh://git@github.com" = {
          insteadOf = "https://github.com";
        };
        "ssh://git@gitlab.com" = {
          insteadOf = "https://gitlab.com";
        };
      };

      diff.tool = "difftastic";
      difftool = {
        prompt = "false";
        difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
      };

      # Taken from https://github.com/clemak27/homecfg/blob/16b86b04bac539a7c9eaf83e9fef4c813c7dce63/modules/git/ssh_signing.nix#L14
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
    };
    ignores = [
      ".direnv"
      "result"
    ];

    # Path-based configurations using Nix includes
    includes = [
      # Gaming repositories configuration
      {
        condition = "gitdir:${config.home.homeDirectory}/src/gaming/";
        contents = {
          user = {
            name = gamingGitName;
            email = gamingGitEmail;
            signingKey = "${sshFolder}/id_github_benway.pub";
          };
          core = {
            sshCommand = "ssh -o IdentitiesOnly=yes -i ~/.ssh/id_github_benway";
          };
          commit = {
            gpgsign = true;
          };
          gpg = {
            format = "ssh";
          };
        };
      }
      # Standard repositories configuration
      {
        condition = "gitdir:${config.home.homeDirectory}/src/";
        contents = {
          user = {
            name = stdGitName;
            email = stdGitEmail;
            signingKey = "${sshFolder}/id_github_slappy.pub";
          };
          core = {
            sshCommand = "ssh -o IdentitiesOnly=yes -i ~/.ssh/id_github_slappy";
          };
          commit = {
            gpgsign = true;
          };
          gpg = {
            format = "ssh";
          };
        };
      }
    ];
  };

  home.file.".ssh/allowed_signers".text = ''
    ${stdGitEmail} ${lib.fileContents (lib.custom.relativeToRoot "hosts/common/users/primary/keys/id_github_slappy.pub")}
    ${gamingGitEmail} ${lib.fileContents (lib.custom.relativeToRoot "hosts/common/users/primary/keys/id_github_benway.pub")}
  '';

}
