# Development utilities I want across all systems
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # sshFolder = "${config.home.homeDirectory}/.ssh";
  # publicKey =
  #   if config.hostSpec.useYubikey then
  #     "${sshFolder}/id_yubikey.pub"
  #   else
  #     "${sshFolder}/id_github_slappy.pub";
  gamingGitEmail = config.hostSpec.gitHub.gaming.email;
  gamingGitName = config.hostSpec.gitHub.gaming.name;
  gamingGitConfig = "${config.home.homeDirectory}/.config/git/gitconfig.gaming";
  stdGitEmail = config.hostSpec.gitHub.std.email;
  stdGitName = config.hostSpec.gitHub.std.name;
  stdGitConfig = "${config.home.homeDirectory}/.config/git/gitconfig.std";
in
{
  imports = lib.custom.scanPaths ./.;

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

        # networking
        nmap

        # Diffing
        difftastic

        # serial debugging
        screen

        # Standard man pages for linux API
        man-pages
        man-pages-posix
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

      includeIf."gitdir:${config.home.homeDirectory}/src/github/gaming/".path = gamingGitConfig;
      includeIf."gitdir:${config.home.homeDirectory}/src/github/".path = stdGitConfig;

      url = {
        "ssh://git@github.com" = {
          insteadOf = "https://github.com";
        };
        "ssh://git@gitlab.com" = {
          insteadOf = "https://gitlab.com";
        };
      };
      core = {
        sshCommand = "ssh -i ~/.ssh/id_github_slappy";
      };

      diff.tool = "difftastic";
      difftool = {
        prompt = "false";
        difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
      };
    };
    ignores = [
      ".direnv"
      "result"
    ];
  };

  home.file."${gamingGitConfig}".text = ''
    [user]
      name = "${gamingGitName}"
      email = ${gamingGitEmail}
    [core]
      sshCommand = "ssh -i ~/.ssh/id_github_benway"
  '';
  home.file."${stdGitConfig}".text = ''
    [user]
      name = "${stdGitName}"
      email = "${stdGitEmail}"
  '';
}
