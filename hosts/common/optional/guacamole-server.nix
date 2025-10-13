# Apache guacamole server daemon (guacd only)

{ pkgs, ... }:
{
  # Enable Guacamole daemon (guacd)
  services.guacamole-server = {
    enable = true;
    host = "0.0.0.0"; # Bind to all interfaces for LAN access
    port = 4822; # Default guacd port
  };

  # Firewall configuration for LAN access
  networking.firewall = {
    allowedTCPPorts = [
      4822 # Guacd daemon
    ];
  };

  # Just the server package
  environment.systemPackages = with pkgs; [
    guacamole-server
  ];
}
