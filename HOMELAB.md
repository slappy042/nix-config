# Homelab


## Networking / Infrastructure
- traefik
- tailscale
  - https://github.com/kiriwalawren/dotnix/blob/main/modules/nixos/system/network/tailscale.nix
  - https://kiriwalawren.github.io/nixflix/reference/mullvad/#using-tailscale-with-mullvad
- mullvad DNS for DNS over HTTPS?
  - probably doesn't matter unless you VPN all traffic

## VMs
- nix VMs: https://github.com/microvm-nix/microvm.nix
- proxmox hypervisor on NixOS: https://github.com/SaumonNet/proxmox-nixos
- proxmox scripts, not Nix-related
  - https://community-scripts.org/

## Services
- vaultwarden / bitwarden
- nextcloud
- Google Workspace for hardy.party

### Arrs
- *arrs
  - nixflix
    - config for *arrs, jellyfin. can probably disable jellyfin
    - https://old.reddit.com/r/NixOS/comments/1qgyi90/announcing_nixflix_a_declarative_nixos_jellyfin/
  - buildarr is dead
  - nixarr installs service, but basically no config
  - https://github.com/recyclarr/recyclarr
    - syncs trash guide settings to local settings
