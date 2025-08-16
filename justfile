SOPS_FILE := "../nix-secrets/.sops.yaml"

# Define path to helpers
export HELPERS_PATH := justfile_directory() + "/scripts/helpers.sh"

# default recipe to display help information
default:
  @just --list

# Update commonly changing flakes and prep for a rebuild
rebuild-pre: update-nix-secrets
  @git add --intent-to-add .

# Run post-rebuild checks, like if sops is running properly afterwards
rebuild-post: check-sops

# Run a flake check on the config and installer
check ARGS="":
  NIXPKGS_ALLOW_UNFREE=1 REPO_PATH=$(pwd) nix flake check --impure --keep-going --show-trace {{ARGS}}
  cd nixos-installer && NIXPKGS_ALLOW_UNFREE=1 REPO_PATH=$(pwd) nix flake check --impure --keep-going --show-trace {{ARGS}}

# Rebuild the system
rebuild LABEL="" HOST="": rebuild-pre && rebuild-post
  # NOTE: Add --option eval-cache false if you end up caching a failure you can't get around
  if [ -z "{{LABEL}}" ]; then \
    GEN_LABEL="$(git -c log.showSignature=false log -1 --pretty=%s | head -n1)"; \
  else \
    GEN_LABEL="{{LABEL}}"; \
  fi; \
  GEN_LABEL_SAFE="$(printf '%s' "$GEN_LABEL" | sed -E 's/[^A-Za-z0-9:_\.-]+/_/g' | sed -E 's/_+/_/g; s/^_|_$//g')"; \
  SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"; \
  TS="$(date +%Y%m%d-%H%M%S)"; \
  GENERATION_LABEL="${GEN_LABEL_SAFE}-${SHORT_SHA}-${TS}" scripts/rebuild.sh {{HOST}}

# Rebuild the system and run a flake check
rebuild-full LABEL="" HOST="": rebuild-pre && rebuild-post
  if [ -z "{{LABEL}}" ]; then \
    GEN_LABEL="$(git -c log.showSignature=false log -1 --pretty=%s | head -n1)"; \
  else \
    GEN_LABEL="{{LABEL}}"; \
  fi; \
  GEN_LABEL_SAFE="$(printf '%s' "$GEN_LABEL" | sed -E 's/[^A-Za-z0-9:_\.-]+/_/g' | sed -E 's/_+/_/g; s/^_|_$//g')"; \
  SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"; \
  TS="$(date +%Y%m%d-%H%M%S)"; \
  GENERATION_LABEL="${GEN_LABEL_SAFE}-${SHORT_SHA}-${TS}" scripts/rebuild.sh {{HOST}}
  just check

# Rebuild the system and run a flake check
rebuild-trace LABEL="" HOST="": rebuild-pre && rebuild-post
  if [ -z "{{LABEL}}" ]; then \
    GEN_LABEL="$(git -c log.showSignature=false log -1 --pretty=%s | head -n1)"; \
  else \
    GEN_LABEL="{{LABEL}}"; \
  fi; \
  GEN_LABEL_SAFE="$(printf '%s' "$GEN_LABEL" | sed -E 's/[^A-Za-z0-9:_\.-]+/_/g' | sed -E 's/_+/_/g; s/^_|_$//g')"; \
  SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"; \
  TS="$(date +%Y%m%d-%H%M%S)"; \
  GENERATION_LABEL="${GEN_LABEL_SAFE}-${SHORT_SHA}-${TS}" scripts/rebuild.sh trace
  just check

# Update the flake
update:
  nix flake update

# Update and then rebuild
rebuild-update: update rebuild

# Git diff there entire repo expcept for flake.lock
diff:
  git diff ':!flake.lock'

# Generate a new age key
age-key:
  nix-shell -p age --run "age-keygen"

# Check if sops-nix activated successfully
check-sops:
  scripts/check-sops.sh

# Update nix-secrets flake
update-nix-secrets:
  @(cd ../nix-secrets && git fetch && git rebase > /dev/null) || true
  nix flake update nix-secrets --timeout 5

# Build an iso image for installing new systems and create a symlink for qemu usage
iso:
  # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
  rm -rf result
  nix build --impure .#nixosConfigurations.iso.config.system.build.isoImage && ln -sf result/iso/*.iso latest.iso

# Install the latest iso to a flash drive
iso-install DRIVE: iso
  sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

# Configure a drive password using disko
disko DRIVE PASSWORD:
  echo "{{PASSWORD}}" > /tmp/disko-password
  sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko \
    disks/btrfs-luks-impermanence-disko.nix \
    --arg disk '"{{DRIVE}}"' \
    --arg password '"{{PASSWORD}}"'
  rm /tmp/disko-password

# Copy all the config files to the remote host
sync USER HOST PATH:
	rsync -av --filter=':- .gitignore' -e "ssh -l {{USER}} -oport=22" . {{USER}}@{{HOST}}:{{PATH}}/nix-config

# Run nixos-rebuild on the remote host
build-host HOST:
	NIX_SSHOPTS="-p22" nixos-rebuild --target-host {{HOST}} --use-remote-sudo --show-trace --impure --flake .#"{{HOST}}" switch

# Called by the rekey recipe
sops-rekey:
  cd ../nix-secrets && for file in $(ls sops/*.yaml); do \
    sops updatekeys -y $file; \
  done

# Update all keys in sops/*.yaml files in nix-secrets to match the creation rules keys
rekey: sops-rekey
  cd ../nix-secrets && \
    (pre-commit run --all-files || true) && \
    git add -u && (git commit -nm "chore: rekey" || true) && git push

# Update an age key anchor or add a new one
sops-update-age-key FIELD KEYNAME KEY:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_update_age_key {{FIELD}} {{KEYNAME}} {{KEY}}

# Update an existing user age key anchor or add a new one
sops-update-user-age-key USER HOST KEY:
  just sops-update-age-key users {{USER}}_{{HOST}} {{KEY}}

# Update an existing host age key anchor or add a new one
sops-update-host-age-key HOST KEY:
  just sops-update-age-key hosts {{HOST}} {{KEY}}

# Automatically create creation rules entries for a <host>.yaml file for host-specific secrets
sops-add-host-creation-rules USER HOST:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_add_host_creation_rules "{{USER}}" "{{HOST}}"

# Automatically create creation rules entries for a shared.yaml file for shared secrets
sops-add-shared-creation-rules USER HOST:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_add_shared_creation_rules "{{USER}}" "{{HOST}}"

# Automatically add the host and user keys to creation rules for shared.yaml and <host>.yaml
sops-add-creation-rules USER HOST:
    just sops-add-host-creation-rules {{USER}} {{HOST}} && \
    just sops-add-shared-creation-rules {{USER}} {{HOST}}

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
  @echo "=== Enabling DSC for AMD GPU Display Connectors ==="; \
  DSC_FILES=$$(sudo find /sys/kernel/debug/dri -name "*dsc*" -type f 2>/dev/null); \
  if [ -z "$$DSC_FILES" ]; then \
    echo "No DSC debugfs controls found. DSC may not be available or already enabled."; \
  else \
    echo "Found DSC controls:"; \
    echo "$$DSC_FILES" | while read file; do \
      echo "  $$file"; \
      echo 1 | sudo tee "$$file" >/dev/null 2>&1 && echo "    ✓ Enabled" || echo "    ✗ Failed"; \
    done; \
  fi; \
  echo -e "\nPost-enable status:"; \
  just amd-dsc-status
