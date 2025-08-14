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
