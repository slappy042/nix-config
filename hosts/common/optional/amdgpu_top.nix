{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.amdgpu_top ];
}
