# Development utilities across all systems
{ pkgs, ... }:
{
  imports = [
    ./git.nix
    ./claude-superpowers.nix
  ];

  home.packages = builtins.attrValues {
    inherit (pkgs)
      # Development
      direnv
      delta # diffing
      # act # github workflow runner
      # gh # github cli
      # glab # gitlab cli

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
  };
}
