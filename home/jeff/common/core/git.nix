{ pkgs, lib, config, configVars, ... }:
let
  homeDirectory = config.home.homeDirectory;
in
{
  sops.secrets = {
    "ssh_keys/github_benway" = {
      path = "${homeDirectory}/.ssh/id_github_benway";
      mode = "0400";
    };
    "ssh_keys/github_slappy" = {
      path = "${homeDirectory}/.ssh/id_github_slappy";
      mode = "0400";
    };
  };
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = configVars.handle;
    userEmail = configVars.gitEmail;
    aliases = { };
    includes = [
      {
        path = "~/src/github/benway/.gitconfig.benway";
        condition = "gitdir:~/src/github/benway/";
      }
    ];

    extraConfig = {
      init.defaultBranch = "main";
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

      # user.signing.key = "41B7B2ECE0FAEF890343124CE8AA1A8F75B56D39";
      #TODO sops - Re-enable once sops setup complete
      commit.gpgSign = false;
      gpg.program = "${config.programs.gpg.package}/bin/gpg2";
    };
    # enable git Large File Storage: https://git-lfs.com/
    # lfs.enable = true;
    ignores = [ ".direnv" "result" ];
  };
  home.file."src/github/benway/.gitconfig.benway".text = ''
    [user]
    email = 75365523+benway7000@users.noreply.github.com
    name = benway7000

    [core]
    sshCommand = "ssh -i ~/.ssh/id_github_benway"
  '';
}
