# Cursor AI code editor (VSCode fork)
# Cursor manages its own extensions and settings via ~/.config/Cursor
# Pulled from unstable: Cursor refuses to run once a release is too old
{ pkgs, ... }:
{
  home.packages = [ pkgs.unstable.code-cursor ];
}
