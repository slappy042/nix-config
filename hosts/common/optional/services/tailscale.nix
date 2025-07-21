# Enable tailscale
{ ... }:
{
  #   services.tailscale.enable = true;
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--accept-dns=false"
    ];
  };
  #   services.tailscale.authKey = "...";
  #   services.tailscale.hostname = "...";
  #   services.tailscale.exitNode = true;
  #   services.tailscale.advertiseRoutes = [ "192.168.1.0/24" ];
  #   services.tailscale.automaticUpdates = true;
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;
}
