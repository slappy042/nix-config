{ pkgs, ... }:
{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      # Process / system monitoring
      btop # resource monitor TUI
      htop # classic top viewer
      iotop # disk I/O by process
      pstree # process tree viewer
      sysstat # iostat, mpstat, pidstat

      # Disk
      ncdu # TUI disk usage
      dust # disk usage (rust, tree-style)
      smartmontools # smartctl - SSD/HDD health

      # Hardware / info
      pciutils # lspci
      usbutils # lsusb
      dmidecode # hardware info from BIOS/UEFI
      lm_sensors # sensors - CPU/mobo temps

      # Network - interface / routing
      inetutils # ifconfig, ftp, telnet
      iproute2 # ip, ss (modern netstat replacement)

      # Network - DNS
      dnsutils # dig, nslookup, host

      # Network - scanning / traffic
      nmap # port scanning, host discovery
      mtr # traceroute + ping combined TUI
      tcpdump # raw packet capture
      nethogs # per-process network monitor
      bandwhich # per-process bandwidth TUI

      # File / process inspection
      lsof # list open files, sockets, ports
      strace # system call tracer
      ;
  };
}
