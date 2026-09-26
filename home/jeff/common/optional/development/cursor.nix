# Cursor AI code editor (VSCode fork)
# Cursor manages its own extensions and settings via ~/.config/Cursor
{ pkgs, ... }:
{
  home.packages = [ pkgs.code-cursor ];
}
