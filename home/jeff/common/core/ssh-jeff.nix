{ config, outputs, lib, ... }:
let
  identityFiles = [
    "id_camelot" # Jeff's default key
  ];
in
{
  programs.ssh = {
    enable = true;

    addKeysToAgent = "yes";

    extraConfig = lib.strings.concatMapStrings(file: "IdentityFile ${config.home.homeDirectory}/.ssh/${file}\n") identityFiles;

    matchBlocks = {
      "git" = {
        host = "gitlab.com github.com";
        user = "git";
        forwardAgent = true;
        identitiesOnly = true;
        identityFile = [
          # "~/.ssh/id_github_benway"
          "~/.ssh/id_github_slappy"
        ];
      };
    };
    # FIXME: This should probably be for git systems only?
    # Should create PR for this to be part of MatchBlocks
    controlMaster = "auto";
    controlPath = "~/.ssh/sockets/S.%r@%h:%p";
    controlPersist = "10m";
  };
  home.file.".ssh/sockets/.keep".text = "# Managed by Home Manager";
}
