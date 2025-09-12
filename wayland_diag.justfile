
# =============================
# Plasma Wayland diagnostics
# =============================
# Collect logs & debug info after a failed Plasma (Wayland) start.
# Usage:
#   just diag          # creates plasma-wayland-debug-<timestamp> directory
#   just diag-archive  # also tars it
# Provide the directory or tarball for analysis.

diag:
  OUTDIR="debug/plasma-wayland-debug-$(date +%Y%m%d-%H%M%S)"; \
  echo "Collecting to ${OUTDIR}"; \
  mkdir -p "${OUTDIR}"; \
  if [ "${SUDO:-0}" = 1 ]; then JCTL="sudo journalctl"; CCTL="sudo coredumpctl"; else JCTL="journalctl"; CCTL="coredumpctl"; fi; \
  ${JCTL} -b -u display-manager > "${OUTDIR}/display-manager.full.log" 2>&1 || true; \
  ${JCTL} -b -u display-manager | grep -iE 'kwin|wayland|plasma' > "${OUTDIR}/display-manager.filtered.log" 2>/dev/null || true; \
  ${JCTL} -b | grep -iE 'kwin|wayland|plasma' > "${OUTDIR}/journal.filtered.log" 2>/dev/null || true; \
  if [ -d "$HOME/.local/share/sddm" ]; then ls -1 "$HOME/.local/share/sddm" > "${OUTDIR}/sddm_dir_listing.txt" 2>/dev/null || true; fi; \
  sed -n '1,400p' "$HOME/.local/share/sddm/wayland-session.log" > "${OUTDIR}/wayland-session.log" 2>/dev/null || true; \
  ${CCTL} -b --user > "${OUTDIR}/coredump.list.txt" 2>/dev/null || true; \
  ${CCTL} -b --user | grep -i kwin > "${OUTDIR}/coredump.kwin.txt" 2>/dev/null || true; \
  lspci -k | grep -A3 -i vga > "${OUTDIR}/lspci-gpu.txt" 2>&1 || true; \
  ls -l /dev/dri > "${OUTDIR}/dev-dri.txt" 2>&1 || true; \
  nix-shell -p mesa-demos --run 'glxinfo -B' > "${OUTDIR}/glxinfo.txt" 2>&1 || true; \
  ls -1 /run/opengl-driver/lib/dri > "${OUTDIR}/dri-modules.txt" 2>/dev/null || true; \
  nix-shell -p weston --run 'weston --version' > "${OUTDIR}/weston-version.txt" 2>&1 || true; \
  DESKTOP=$(ls /nix/store/*-desktops/share/wayland-sessions/plasma.desktop 2>/dev/null | head -n1); \
  if [ -n "$DESKTOP" ]; then grep -E '^(Exec|Name|TryExec)=' "$DESKTOP" > "${OUTDIR}/plasma.desktop.lines" 2>/dev/null || true; fi; \
  SCRIPT=$(ls /nix/store/*-sddm-unwrapped-*/share/sddm/scripts/wayland-session 2>/dev/null | head -n1); \
  if [ -n "$SCRIPT" ]; then sed -n '1,120p' "$SCRIPT" > "${OUTDIR}/sddm-wayland-session.head" 2>/dev/null || true; fi; \
  WRAP=$(ls /nix/store/*-plasma-workspace-*/libexec/plasma-dbus-run-session-if-needed 2>/dev/null | head -n1); \
  if [ -n "$WRAP" ]; then head -n 60 "$WRAP" > "${OUTDIR}/plasma-dbus-run-session-if-needed.head" 2>/dev/null || true; fi; \
  echo "${OUTDIR}" > .last-plasma-diag-dir; \
  echo "Done. See ${OUTDIR}"; \
  echo "(Manual Wayland start disabled in diag. Use: just start-plasma-wayland)"

# Dump entire SDDM wayland-session script (for deeper inspection)
dump-wayland-session-script:
  SCRIPT=$(ls /nix/store/*-sddm-unwrapped-*/share/sddm/scripts/wayland-session 2>/dev/null | head -n1); \
  if [ -z "$SCRIPT" ]; then echo "Not found" >&2; exit 1; fi; \
  echo "Script: $SCRIPT"; \
  sed -n '1,200p' "$SCRIPT" | nl

# Manual start of full Plasma Wayland session (captures output). Optional OUTDIR param.
start-plasma-wayland OUTDIR="":
  if [ -z "{{OUTDIR}}" ]; then OUTDIR=$(cat .last-plasma-diag-dir 2>/dev/null || echo "plasma-manual-$(date +%Y%m%d-%H%M%S)"); else OUTDIR="{{OUTDIR}}"; fi; \
  mkdir -p "${OUTDIR}"; \
  echo "Launching startplasma-wayland (dbus-run-session) -> ${OUTDIR}/manual-startplasma-wayland.out"; \
  dbus-run-session startplasma-wayland > "${OUTDIR}/manual-startplasma-wayland.out" 2>&1 & disown || true; \
  echo "Started (check log)."

# Manual minimal KWin Wayland compositor (with XWayland) for isolation.
start-kwin-wayland OUTDIR="":
  if [ -z "{{OUTDIR}}" ]; then OUTDIR=$(cat .last-plasma-diag-dir 2>/dev/null || echo "kwin-manual-$(date +%Y%m%d-%H%M%S)"); else OUTDIR="{{OUTDIR}}"; fi; \
  mkdir -p "${OUTDIR}"; \
  echo "Launching kwin_wayland --xwayland -> ${OUTDIR}/manual-kwin_wayland.out"; \
  dbus-run-session kwin_wayland --xwayland > "${OUTDIR}/manual-kwin_wayland.out" 2>&1 & disown || true; \
  echo "Started (check log)."

# =============================
# SDDM Multi-Monitor Boot diagnostics
# =============================
# Collect logs & debug info for SDDM startup issues with multiple monitors.
# Use this when SDDM won't load with 3 monitors but works with fewer.

sddm-diag:
  OUTDIR="debug/sddm-multimon-debug-$(date +%Y%m%d-%H%M%S)"; \
  echo "Collecting SDDM multi-monitor diagnostics to ${OUTDIR}"; \
  mkdir -p "${OUTDIR}"; \
  if [ "${SUDO:-0}" = 1 ]; then JCTL="sudo journalctl"; SUDO_CMD="sudo"; else JCTL="journalctl"; SUDO_CMD=""; fi; \
  echo "=== Display & GPU Info ===" > "${OUTDIR}/system-info.txt"; \
  lspci -k | grep -A5 -B2 -i "vga\|3d\|display" >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo -e "\n=== DRM Devices ===" >> "${OUTDIR}/system-info.txt"; \
  ls -la /dev/dri/ >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo -e "\n=== Current Displays (if any) ===" >> "${OUTDIR}/system-info.txt"; \
  (xrandr 2>/dev/null || wayland-info 2>/dev/null || echo "No display server running") >> "${OUTDIR}/system-info.txt" 2>&1; \
  echo -e "\n=== Kernel Display Modules ===" >> "${OUTDIR}/system-info.txt"; \
  lsmod | grep -E "(drm|i915|nvidia|amdgpu|radeon)" >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo -e "\n=== Boot Messages (GPU/DRM related) ===" > "${OUTDIR}/boot-gpu.log"; \
  ${JCTL} -b | grep -iE "(drm|gpu|display|monitor|edid|dp|hdmi|vga)" >> "${OUTDIR}/boot-gpu.log" 2>&1 || true; \
  echo "=== SDDM Service Logs (current boot) ===" > "${OUTDIR}/sddm-service.log"; \
  ${JCTL} -b -u sddm >> "${OUTDIR}/sddm-service.log" 2>&1 || echo "Failed to get SDDM logs (try: SUDO=1 just sddm-diag)" >> "${OUTDIR}/sddm-service.log"; \
  echo "=== Display Manager Logs (current boot) ===" > "${OUTDIR}/display-manager.log"; \
  ${JCTL} -b -u display-manager >> "${OUTDIR}/display-manager.log" 2>&1 || echo "Failed to get display-manager logs (try: SUDO=1 just sddm-diag)" >> "${OUTDIR}/display-manager.log"; \
  echo "=== Systemd Boot Timeline ===" > "${OUTDIR}/boot-timeline.log"; \
  systemd-analyze blame >> "${OUTDIR}/boot-timeline.log" 2>&1 || true; \
  echo -e "\n=== Critical Path ===" >> "${OUTDIR}/boot-timeline.log"; \
  systemd-analyze critical-chain >> "${OUTDIR}/boot-timeline.log" 2>&1 || true; \
  echo "=== SDDM Configuration ===" > "${OUTDIR}/sddm-config.txt"; \
  find /etc/sddm* -name "*.conf" -exec echo "=== {} ===" \; -exec cat {} \; >> "${OUTDIR}/sddm-config.txt" 2>/dev/null || true; \
  find /run/current-system/etc/sddm* -name "*.conf" -exec echo "=== {} ===" \; -exec ${SUDO_CMD} cat {} \; >> "${OUTDIR}/sddm-config.txt" 2>/dev/null || echo "Some SDDM config files may need sudo access" >> "${OUTDIR}/sddm-config.txt"; \
  echo "=== Xorg Logs (if any) ===" > "${OUTDIR}/xorg-logs.txt"; \
  ${SUDO_CMD} find /var/log -name "Xorg*.log" -exec echo "=== {} ===" \; -exec tail -n 100 {} \; >> "${OUTDIR}/xorg-logs.txt" 2>/dev/null || echo "Xorg logs may need sudo access" >> "${OUTDIR}/xorg-logs.txt"; \
  find /home/*/.local/share/sddm -name "xorg-session.log" -exec echo "=== {} ===" \; -exec tail -n 100 {} \; >> "${OUTDIR}/xorg-logs.txt" 2>/dev/null || true; \
  echo "=== Kernel Command Line ===" > "${OUTDIR}/kernel-cmdline.txt"; \
  cat /proc/cmdline >> "${OUTDIR}/kernel-cmdline.txt" 2>&1 || true; \
  echo -e "\n=== Framebuffer Info ===" >> "${OUTDIR}/kernel-cmdline.txt"; \
  cat /proc/fb >> "${OUTDIR}/kernel-cmdline.txt" 2>/dev/null || echo "No framebuffer info available" >> "${OUTDIR}/kernel-cmdline.txt"; \
  echo "=== Udev Rules (display related) ===" > "${OUTDIR}/udev-display.txt"; \
  find /etc/udev/rules.d /run/udev/rules.d /lib/udev/rules.d /nix/store -name "*drm*" -o -name "*gpu*" -o -name "*display*" 2>/dev/null | head -20 >> "${OUTDIR}/udev-display.txt" || true; \
  echo -e "\n=== Environment Variables ===" >> "${OUTDIR}/system-info.txt"; \
  env | grep -iE "(display|wayland|xdg|qt)" >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo "${OUTDIR}" > .last-sddm-diag-dir; \
  echo "Done. SDDM multi-monitor diagnostics saved to ${OUTDIR}"; \
  echo "If some logs are missing, try: SUDO=1 just sddm-diag"; \
  echo "To reproduce: boot with 3 monitors connected and run this after the hang."

# Archive the latest SDDM diagnostics
sddm-diag-archive:
  OUTDIR=$(cat .last-sddm-diag-dir 2>/dev/null || echo "debug/sddm-multimon-debug-$(date +%Y%m%d-%H%M%S)"); \
  if [ ! -d "${OUTDIR}" ]; then echo "No diagnostics directory found. Run 'just sddm-diag' first."; exit 1; fi; \
  tar -czf "${OUTDIR}.tar.gz" "${OUTDIR}"; \
  echo "Archived to ${OUTDIR}.tar.gz"

# Collect logs from PREVIOUS boot (useful after a hang/reboot)
sddm-diag-previous:
  OUTDIR="debug/sddm-multimon-previous-$(date +%Y%m%d-%H%M%S)"; \
  echo "Collecting SDDM diagnostics from PREVIOUS boot to ${OUTDIR}"; \
  mkdir -p "${OUTDIR}"; \
  if [ "${SUDO:-0}" = 1 ]; then JCTL="sudo journalctl"; SUDO_CMD="sudo"; else JCTL="journalctl"; SUDO_CMD=""; fi; \
  echo "=== Display & GPU Info ===" > "${OUTDIR}/system-info.txt"; \
  lspci -k | grep -A5 -B2 -i "vga\|3d\|display" >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo -e "\n=== DRM Devices ===" >> "${OUTDIR}/system-info.txt"; \
  ls -la /dev/dri/ >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo -e "\n=== Kernel Display Modules ===" >> "${OUTDIR}/system-info.txt"; \
  lsmod | grep -E "(drm|i915|nvidia|amdgpu|radeon)" >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo "=== PREVIOUS Boot Messages (GPU/DRM related) ===" > "${OUTDIR}/boot-gpu-previous.log"; \
  ${JCTL} -b -1 | grep -iE "(drm|gpu|display|monitor|edid|dp|hdmi|vga)" >> "${OUTDIR}/boot-gpu-previous.log" 2>&1 || echo "Failed to get previous boot logs (try: SUDO=1 just sddm-diag-previous)" >> "${OUTDIR}/boot-gpu-previous.log"; \
  echo "=== PREVIOUS SDDM Service Logs ===" > "${OUTDIR}/sddm-service-previous.log"; \
  ${JCTL} -b -1 -u sddm >> "${OUTDIR}/sddm-service-previous.log" 2>&1 || echo "Failed to get previous SDDM logs (try: SUDO=1 just sddm-diag-previous)" >> "${OUTDIR}/sddm-service-previous.log"; \
  echo "=== PREVIOUS Display Manager Logs ===" > "${OUTDIR}/display-manager-previous.log"; \
  ${JCTL} -b -1 -u display-manager >> "${OUTDIR}/display-manager-previous.log" 2>&1 || echo "Failed to get previous display-manager logs (try: SUDO=1 just sddm-diag-previous)" >> "${OUTDIR}/display-manager-previous.log"; \
  echo "=== CURRENT Boot Messages (for comparison) ===" > "${OUTDIR}/boot-gpu-current.log"; \
  ${JCTL} -b | grep -iE "(drm|gpu|display|monitor|edid|dp|hdmi|vga)" >> "${OUTDIR}/boot-gpu-current.log" 2>&1 || true; \
  echo "=== CURRENT SDDM Service Logs ===" > "${OUTDIR}/sddm-service-current.log"; \
  ${JCTL} -b -u sddm >> "${OUTDIR}/sddm-service-current.log" 2>&1 || echo "Failed to get current SDDM logs (try: SUDO=1 just sddm-diag-previous)" >> "${OUTDIR}/sddm-service-current.log"; \
  echo "=== CURRENT Display Manager Logs ===" > "${OUTDIR}/display-manager-current.log"; \
  ${JCTL} -b -u display-manager >> "${OUTDIR}/display-manager-current.log" 2>&1 || echo "Failed to get current display-manager logs (try: SUDO=1 just sddm-diag-previous)" >> "${OUTDIR}/display-manager-current.log"; \
  echo "=== SDDM Configuration ===" > "${OUTDIR}/sddm-config.txt"; \
  find /etc/sddm* -name "*.conf" -exec echo "=== {} ===" \; -exec cat {} \; >> "${OUTDIR}/sddm-config.txt" 2>/dev/null || true; \
  find /run/current-system/etc/sddm* -name "*.conf" -exec echo "=== {} ===" \; -exec ${SUDO_CMD} cat {} \; >> "${OUTDIR}/sddm-config.txt" 2>/dev/null || echo "Some SDDM config files may need sudo access" >> "${OUTDIR}/sddm-config.txt"; \
  echo "=== Kernel Command Line ===" > "${OUTDIR}/kernel-cmdline.txt"; \
  cat /proc/cmdline >> "${OUTDIR}/kernel-cmdline.txt" 2>&1 || true; \
  echo -e "\n=== Environment Variables ===" >> "${OUTDIR}/system-info.txt"; \
  env | grep -iE "(display|wayland|xdg|qt)" >> "${OUTDIR}/system-info.txt" 2>&1 || true; \
  echo "${OUTDIR}" > .last-sddm-diag-dir; \
  echo "Done. Previous boot diagnostics saved to ${OUTDIR}"; \
  echo "Key files: boot-gpu-previous.log, sddm-service-previous.log, display-manager-previous.log"; \
  echo "Compare with current boot logs to see differences."

# Check and manage AMD GPU DSC (Display Stream Compression) settings
amd-dsc-status:
  echo "=== AMD GPU DSC Status ==="; \
  echo "Current amdgpu parameters:"; \
  echo "  dc: $(cat /sys/module/amdgpu/parameters/dc 2>/dev/null || echo 'N/A')"; \
  echo "  dcfeaturemask: $(cat /sys/module/amdgpu/parameters/dcfeaturemask 2>/dev/null || echo 'N/A')"; \
  echo "  dcdebugmask: $(cat /sys/module/amdgpu/parameters/dcdebugmask 2>/dev/null || echo 'N/A')"; \
  echo -e "\nKernel command line DSC setting:"; \
  grep -o 'amdgpu\.dsc=[0-9]*' /proc/cmdline 2>/dev/null || echo "  No explicit amdgpu.dsc parameter found"; \
  echo -e "\nAvailable DRM debugfs DSC controls:"; \
  sudo find /sys/kernel/debug/dri -name "*dsc*" -type f 2>/dev/null | head -10 || echo "  No DSC debugfs controls found (may need sudo)"; \
  echo -e "\nDSC capability in current displays:"; \
  xrandr --verbose 2>/dev/null | grep -E "(^[A-Z]|DSC)" || echo "  No display server running or no DSC info available"

# Enable DSC for all available display connectors (requires sudo)
amd-dsc-enable:
  #!/usr/bin/env bash
  echo "=== Enabling DSC for AMD GPU Display Connectors ==="
  DSC_FILES=$(sudo find /sys/kernel/debug/dri -name "*dsc*" -type f 2>/dev/null)
  if [ -z "$DSC_FILES" ]; then
    echo "No DSC debugfs controls found. DSC may not be available or already enabled."
  else
    echo "Found DSC controls:"
    for file in $DSC_FILES; do
      echo "  $file"
      if [[ "$file" == *"dsc_disable_passthrough" ]]; then
        echo 0 | sudo tee "$file" >/dev/null 2>&1 && echo "    ✓ DSC passthrough disabled (DSC enabled)" || echo "    ✗ Failed"
      else
        echo 1 | sudo tee "$file" >/dev/null 2>&1 && echo "    ✓ Enabled" || echo "    ✗ Failed"
      fi
    done
  fi
  echo -e "\nPost-enable status:"
  just amd-dsc-status

# Comprehensive boot hang diagnosis - capture detailed timing
boot-hang-diag:
  OUTDIR="debug/boot-hang-debug-$(date +%Y%m%d-%H%M%S)"; \
  echo "Collecting comprehensive boot hang diagnostics to ${OUTDIR}"; \
  mkdir -p "${OUTDIR}"; \
  if [ "${SUDO:-0}" = 1 ]; then JCTL="sudo journalctl"; else JCTL="journalctl"; fi; \
  echo "=== Kernel Command Line ===" > "${OUTDIR}/kernel-params.txt"; \
  cat /proc/cmdline >> "${OUTDIR}/kernel-params.txt" 2>&1 || true; \
  echo -e "\n=== AMD GPU Module Parameters ===" >> "${OUTDIR}/kernel-params.txt"; \
  find /sys/module/amdgpu/parameters -type f -exec echo "  {}: $(cat {})" \; >> "${OUTDIR}/kernel-params.txt" 2>/dev/null || true; \
  echo -e "\n=== DRM Module Parameters ===" >> "${OUTDIR}/kernel-params.txt"; \
  find /sys/module/drm/parameters -type f -exec echo "  {}: $(cat {})" \; >> "${OUTDIR}/kernel-params.txt" 2>/dev/null || true; \
  echo "=== Boot Timeline Analysis ===" > "${OUTDIR}/boot-analysis.txt"; \
  systemd-analyze >> "${OUTDIR}/boot-analysis.txt" 2>&1 || true; \
  echo -e "\n=== Detailed Service Timing ===" >> "${OUTDIR}/boot-analysis.txt"; \
  systemd-analyze blame | head -30 >> "${OUTDIR}/boot-analysis.txt" 2>&1 || true; \
  echo -e "\n=== Critical Chain ===" >> "${OUTDIR}/boot-analysis.txt"; \
  systemd-analyze critical-chain display-manager.service >> "${OUTDIR}/boot-analysis.txt" 2>&1 || true; \
  echo "=== MST/DSC Boot Messages ===" > "${OUTDIR}/mst-dsc-boot.log"; \
  ${JCTL} -b | grep -iE "(mst|dsc|stream|compression|dp.*link|timeout|hang|amdgpu.*dc)" >> "${OUTDIR}/mst-dsc-boot.log" 2>&1 || echo "No MST/DSC messages found" >> "${OUTDIR}/mst-dsc-boot.log"; \
  echo "=== Display Port Boot Messages ===" > "${OUTDIR}/displayport-boot.log"; \
  ${JCTL} -b | grep -iE "(displayport|dp.*[0-9]|edid.*dp|link.*train)" >> "${OUTDIR}/displayport-boot.log" 2>&1 || echo "No DisplayPort messages found" >> "${OUTDIR}/displayport-boot.log"; \
  echo "=== AMD GPU Initialization ===" > "${OUTDIR}/amdgpu-init.log"; \
  ${JCTL} -b | grep -iE "(amdgpu.*init|dc.*init|dm.*init|kms.*init)" >> "${OUTDIR}/amdgpu-init.log" 2>&1 || echo "No AMD GPU init messages found" >> "${OUTDIR}/amdgpu-init.log"; \
  echo "=== Current MST Topology (if available) ===" > "${OUTDIR}/mst-topology.txt"; \
  sudo find /sys/kernel/debug/dri -name "*mst*" -type d 2>/dev/null | while read mst_dir; do \
    echo "=== $mst_dir ===" >> "${OUTDIR}/mst-topology.txt"; \
    sudo find "$mst_dir" -type f 2>/dev/null | head -10 | while read file; do \
      echo "  $file: $(sudo cat "$file" 2>/dev/null | head -5)" >> "${OUTDIR}/mst-topology.txt" 2>/dev/null || true; \
    done; \
  done; \
  echo "=== Current Display Connectors ===" > "${OUTDIR}/display-connectors.txt"; \
  sudo find /sys/class/drm -name "card0-DP-*" -type l 2>/dev/null | sort | while read connector; do \
    echo "=== $connector ===" >> "${OUTDIR}/display-connectors.txt"; \
    echo "  Status: $(sudo cat "$connector/status" 2>/dev/null || echo 'unknown')" >> "${OUTDIR}/display-connectors.txt"; \
    echo "  Enabled: $(sudo cat "$connector/enabled" 2>/dev/null || echo 'unknown')" >> "${OUTDIR}/display-connectors.txt"; \
    echo "  DPMS: $(sudo cat "$connector/dpms" 2>/dev/null || echo 'unknown')" >> "${OUTDIR}/display-connectors.txt"; \
  done; \
  echo "${OUTDIR}" > .last-boot-hang-diag-dir; \
  echo "Done. Boot hang diagnostics saved to ${OUTDIR}"; \
  echo "Key files: mst-dsc-boot.log, boot-analysis.txt, kernel-params.txt"

# Test alternative kernel parameters for MST/multi-monitor issues
suggest-alt-kernelparams:
  echo "=== Current Kernel Parameters ==="; \
  grep -E "(amdgpu|drm)" /proc/cmdline | tr ' ' '\n' | grep -E "(amdgpu|drm)"; \
  echo -e "\n=== Suggested Alternative Parameters to Test ==="; \
  echo "Option 1 - Disable early KMS and force single-threaded init:"; \
  echo "  amdgpu.modeset=1 amdgpu.dc=1 amdgpu.dce_use_kgd_interface=0"; \
  echo "  drm.atomic=0 amdgpu.runpm=0 amdgpu.audio=0"; \
  echo -e "\nOption 2 - Force specific display timing:"; \
  echo "  amdgpu.modeset=1 amdgpu.dc=1 amdgpu.dsc=0"; \
  echo "  drm.edid_firmware=edid/1920x1080.bin video=DP-1:1920x1080@60"; \
  echo -e "\nOption 3 - Minimal AMD GPU features:"; \
  echo "  amdgpu.modeset=1 amdgpu.dc=0 amdgpu.dpm=0"; \
  echo "  amdgpu.powerplay=0 amdgpu.gpu_recovery=0"; \
  echo -e "\nOption 4 - Force synchronous initialization (LATEST BUILD):"; \
  echo "  amdgpu.modeset=1 amdgpu.dc=1 amdgpu.async_gfx_ring=0"; \
  echo "  drm.atomic=0 drm.vblankoffdelay=1 amdgpu.runpm=0 amdgpu.audio=0"; \
  echo -e "\nOption 5 - Original MST/DSC timeout approach:"; \
  echo "  amdgpu.modeset=1 drm.mst_mgr_timeout=20000 amdgpu.dc=1"; \
  echo "  amdgpu.dsc=0 amdgpu.audio=1 drm.debug=0x10"; \
  echo -e "\nCURRENT STATUS: Running Option 5 (MST timeout) - need to reboot to test Option 4"; \
  echo "NEXT: Reboot with 3 monitors to test latest 'try-synchronous-init-approach' generation"

# Quick check if the latest boot resolved the multi-monitor hang
check-boot-hang:
  echo "=== Latest Boot Analysis ==="; \
  echo "Boot time: $(systemd-analyze | head -1)"; \
  echo "Display manager status: $(systemctl is-active display-manager)"; \
  echo -e "\nChecking for MST/DSC timeout messages..."; \
  journalctl -b | grep -iE "(timeout|hang.*display|mst.*timeout)" | wc -l | \
    while read count; do \
      if [ "$count" -gt 0 ]; then \
        echo "❌ Found $count timeout/hang messages - issue may persist"; \
        journalctl -b | grep -iE "(timeout|hang.*display|mst.*timeout)" | head -5; \
      else \
        echo "✅ No timeout/hang messages found - hang likely resolved"; \
      fi; \
    done; \
  echo -e "\nCurrent kernel parameters:"; \
  cat /proc/cmdline | tr ' ' '\n' | grep -E "(amdgpu|drm)" | sort
