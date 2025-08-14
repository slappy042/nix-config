{
  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = false; # disable default Zsh integration, because we use a conditional integration in zsh/default.nix, to avoid zellij in VSCode terminals
  };
}
