# Enable RDP server for remote desktop access via Remmina/other RDP clients

{ pkgs, ... }:
{
  # Enable xrdp for RDP connections
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11"; # Use KDE Plasma for RDP sessions
    openFirewall = true; # Automatically open port 3389
  };

  # Ensure required packages are available
  environment.systemPackages = with pkgs; [
    xrdp
  ];

  # Allow RDP through firewall (redundant with openFirewall = true, but explicit)
  networking.firewall = {
    allowedTCPPorts = [ 3389 ]; # Standard RDP port
  };

  # Optional: Configure xrdp for better performance
  environment.etc."xrdp/xrdp.ini".text = ''
    [Globals]
    ; Specify the startup_window_manager
    startup_window_manager=startplasma-x11
    ; Enable bitmap compression
    bitmap_compression=true
    ; Set security layer
    security_layer=rdp
    ; Certificate and key files
    certificate=
    key_file=
    ; Port to listen on
    port=3389
    ; Maximum number of connections
    max_bpp=32
    fork=true
    tcp_nodelay=true
    tcp_keepalive=true

    [xrdp1]
    name=sesman-Xvnc
    lib=libvnc.so
    username=ask
    password=ask
    ip=127.0.0.1
    port=-1
    xserverbpp=24
  '';
}
