# Personal git identity — signing, path-based identity switching, difftool
# Base git setup (enable, delta, URL rewrites) lives in core/git.nix
{ config, lib, ... }:
let
  sshFolder = "${config.home.homeDirectory}/.ssh";
  publicKey =
    if config.hostSpec.useYubikey then
      "${sshFolder}/id_yubikey.pub"
    else
      "${sshFolder}/id_github_slappy.pub";
  gamingGitEmail = config.hostSpec.github.gaming.email;
  gamingGitName = config.hostSpec.github.gaming.name;
  stdGitEmail = config.hostSpec.github.std.email;
  stdGitName = config.hostSpec.github.std.name;
in
{
  programs.git.settings = {
    user.name = stdGitName;
    user.email = stdGitEmail;

    # FIXME(git): better place for this?
    save.directory = "${config.home.homeDirectory}/sync/obsidian-vault-01/wiki";

    log.showSignature = "true";
    init.defaultBranch = "main";

    advice.addEmptyPathspec = false;

    gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";

    diff.tool = "difftastic";
    difftool = {
      prompt = "false";
      difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
    };
  };

  programs.git.includes = [
    # Gaming repositories
    {
      condition = "gitdir:${config.home.homeDirectory}/src/gaming/";
      contents = {
        user = {
          name = gamingGitName;
          email = gamingGitEmail;
          signingKey = "${sshFolder}/id_github_benway.pub";
        };
        core.sshCommand = "ssh -o IdentitiesOnly=yes -i ~/.ssh/id_github_benway";
        commit.gpgsign = true;
        gpg.format = "ssh";
      };
    }
    # Standard repositories
    {
      condition = "gitdir:${config.home.homeDirectory}/src/";
      contents = {
        user = {
          name = stdGitName;
          email = stdGitEmail;
          signingKey = "${sshFolder}/id_github_slappy.pub";
        };
        core.sshCommand = "ssh -o IdentitiesOnly=yes -i ~/.ssh/id_github_slappy";
        commit.gpgsign = true;
        gpg.format = "ssh";
      };
    }
  ];

  home.file.".ssh/allowed_signers".text = ''
    ${stdGitEmail} ${lib.fileContents (lib.custom.relativeToRoot "hosts/common/users/primary/keys/id_github_slappy.pub")}
    ${gamingGitEmail} ${lib.fileContents (lib.custom.relativeToRoot "hosts/common/users/primary/keys/id_github_benway.pub")}
  '';
}
