{ outputs, lib, ... }:
{
  programs.ssh = {
    enable = true;

    # req'd for enabling yubikey-agent
    extraConfig = ''
      AddKeysToAgent yes
    '';

    matchBlocks = {
      "git" = {
        host = "gitlab.com github.com";
        user = "git";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = [
          "~/.ssh/id_github_benway"
          "~/.ssh/id_github_slappy"
        ];
      };
    };
    # FIXME: This should probably be for git systems only?
    #controlMaster = "auto";
    #controlPath = "~/.ssh/sockets/S.%r@%h:%p";
    #controlPersist = "60m";

    #extraConfig = ''
    #Include config.d/*
    #'';
  };
  #  home.file.".ssh/sockets/.keep".text = "# Managed by Home Manager";
}
