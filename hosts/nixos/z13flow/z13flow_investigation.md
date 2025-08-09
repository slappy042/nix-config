Collecting logs about failed boots

Errors and warnings (prev boot): sudo journalctl --boot -1 -p 0..4 --no-pager -o short-iso -n 400

Display manager (SDDM) logs: sudo journalctl --boot -1 -u display-manager --no-pager -o short-iso

SDDM greeter logs: sudo journalctl --boot -1 -t sddm-greeter-qt6 --no-pager -o short-precise

SDDM Wayland launcher logs: sudo journalctl --boot -1 -t sddm-helper-start-wayland --no-pager -o short-precise

Kernel DRM/AMDGPU messages: sudo journalctl --boot -1 -k --no-pager | grep -i -E 'amdgpu|drm|gpu|timeout|reset|hang|xid'

Any coredumps for greeter/kwin: coredumpctl --boot -1 list | grep -Ei 'sddm|greeter|kwin' coredumpctl --boot -1 info sddm-greeter-qt6 # if listed



Quick next steps:

If you were docked/with external monitors, try an undocked boot once.
Force KWin to use the AMD GPU:
Set: systemd.services.display-manager.environment.KWIN_DRM_DEVICES = "/dev/dri/card1";
This keeps SDDM on Wayland, just points KWin at the real GPU.
Rebuild and reboot. After boot, verify: ls -l /dev/dri (amdgpu should be card1; your logs show amdgpu on minor 1).
If it still crashes:

Temporary workaround: run SDDM on X11 but keep Plasma Wayland (SDDM Wayland off, defaultSession “plasma”).
Want me to add the KWIN_DRM_DEVICES env for the display-manager now?

```bash
sudo readlink -f /run/current-system
sudo readlink -f /nix/var/nix/profiles/system
# If they match, you’re running the latest switched generation.
```
