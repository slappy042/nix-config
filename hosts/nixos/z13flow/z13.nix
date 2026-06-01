{ pkgs, ... }:
let
  chgrp = "${pkgs.coreutils}/bin/chgrp";
  chmod = "${pkgs.coreutils}/bin/chmod";

  # udev RUN+= scripts for rules requiring glob expansion (%p = kernel device path)
  fanCurvePermsScript = pkgs.writeShellScript "z13ctl-fan-curve-perms" ''
    for f in /sys$1/pwm*; do
      [ -e "$f" ] && ${chgrp} users "$f" && ${chmod} g+w "$f"
    done
  '';

  hwmonEnablePermsScript = pkgs.writeShellScript "z13ctl-hwmon-enable-perms" ''
    for f in /sys$1/pwm*_enable; do
      [ -e "$f" ] && ${chgrp} users "$f" && ${chmod} g+w "$f"
    done
  '';

  pptPermsScript = pkgs.writeShellScript "z13ctl-ppt-perms" ''
    for f in /sys/devices/platform/asus-nb-wmi/ppt_*; do
      [ -e "$f" ] && ${chgrp} users "$f" && ${chmod} g+w "$f"
    done
  '';

  # service script: late-init sysfs files that udev RUN+= cannot catch
  # (charge_control_end_threshold created after all udev add events; ryzen_smu not under udev)
  z13ctlPermsScript = pkgs.writeShellScript "z13ctl-perms" ''
    for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
      [ -e "$f" ] && ${chgrp} users "$f" && ${chmod} g+w "$f"
    done
    for f in /sys/class/firmware-attributes/asus-armoury/attributes/boot_sound/current_value \
             /sys/class/firmware-attributes/asus-armoury/attributes/panel_overdrive/current_value; do
      [ -e "$f" ] && ${chgrp} users "$f" && ${chmod} g+w "$f"
    done
    for f in /sys/kernel/ryzen_smu_drv/smu_args \
             /sys/kernel/ryzen_smu_drv/mp1_smu_cmd \
             /sys/kernel/ryzen_smu_drv/rsmu_cmd; do
      [ -e "$f" ] && ${chgrp} users "$f" && ${chmod} g+w "$f" || true
    done
  '';
in
{
  environment.systemPackages = with pkgs; [
    z13ctl
    z13gui
  ];

  # ASUS WMI platform driver for keyboard backlight and firmware attributes
  boot.kernelModules = [ "asus-wmi" ];

  boot.kernelParams = [
    "asus_wmi.fnlock_default=0" # Ensure Fn+F keys work for hardware controls
  ];

  # z13ctl daemon: user-level socket-activated service
  # Hardware access (hidraw) is granted via udev rules below
  systemd.user.sockets.z13ctl = {
    description = "z13ctl daemon socket";
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "%t/z13ctl/z13ctl.sock";
      SocketMode = "0660";
      DirectoryMode = "0750";
    };
  };

  systemd.user.services.z13ctl = {
    description = "z13ctl daemon for ASUS ROG Flow Z13 2025";
    after = [ "z13ctl.socket" ];
    requires = [ "z13ctl.socket" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.z13ctl}/bin/z13ctl daemon";
      Restart = "on-failure";
    };
  };

  # Set keyboard backlight on when on AC power at boot
  systemd.services.keyboard-backlight-default = {
    description = "Set keyboard backlight on when on AC power";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-backlight@leds:asus::kbd_backlight.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${''
        # Check if on AC power
        if ls /sys/class/power_supply/A{C,DP}* >/dev/null 2>&1; then
          for ac in /sys/class/power_supply/A{C,DP}*; do
            if [ -f "$ac/online" ] && [ "$(cat "$ac/online")" = "1" ]; then
              # Set main keyboard backlight to maximum
              echo 3 > /sys/class/leds/asus::kbd_backlight/brightness || true
              exit 0
            fi
          done
        fi
        # If not on AC power, turn off backlight
        echo 0 > /sys/class/leds/asus::kbd_backlight/brightness || true
      ''}'";
      RemainAfterExit = true;
    };
  };

  # Equivalent of 'sudo z13ctl setup' step 3: systemd service for late-init sysfs permissions.
  # charge_control_end_threshold is created after all udev add events (asus_nb_wmi probe() race).
  # ryzen_smu files are under /sys/kernel/, not under a udev subsystem.
  systemd.services.z13ctl-perms = {
    description = "z13ctl sysfs permissions (battery + firmware-attributes + ryzen_smu)";
    after = [ "sysinit.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${z13ctlPermsScript}";
    };
  };

  # z13gui overlay: starts at login, bound to the graphical session
  systemd.user.services.z13gui = {
    description = "z13gui GTK4 overlay for ASUS ROG Flow Z13 2025";
    wantedBy = [ "graphical-session.target" ];
    after = [
      "graphical-session.target"
      "z13ctl.service"
    ];
    requires = [ "z13ctl.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.z13gui}/bin/z13gui";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };

  # Set RGB keyboard to steady white at login (user service, runs after z13ctl daemon)
  # Verify exact subcommand with: z13ctl --help
  systemd.user.services.keyboard-rgb-default = {
    description = "Set RGB keyboard to steady white color";
    wantedBy = [ "graphical-session.target" ];
    after = [ "z13ctl.service" ];
    requires = [ "z13ctl.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.z13ctl}/bin/z13ctl rgb static ffffff";
      RemainAfterExit = true;
    };
  };

  # Udev rules: replaces 'sudo z13ctl setup' steps 1–2
  services.udev.extraRules = ''
    # ASUS HID devices (keyboard RGB: 18c6, lightbar/USB: 1a30) — z13ctl daemon access
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="18c6", MODE="0660", GROUP="users"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="1a30", MODE="0660", GROUP="users"

    # Platform profile attribute (performance modes: quiet/balanced/performance)
    ACTION=="add", SUBSYSTEM=="platform-profile", RUN+="${chgrp} users /sys%p/profile", RUN+="${chmod} g+w /sys%p/profile"
    ACTION=="add", SUBSYSTEM=="platform-profile", KERNELS=="asus-nb-wmi", RUN+="${chgrp} users /sys/class/power_supply/BAT0/charge_control_end_threshold", RUN+="${chmod} g+w /sys/class/power_supply/BAT0/charge_control_end_threshold"

    # Asus WMI hotkeys input device (Armoury Crate button)
    ACTION=="add", SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="Asus WMI hotkeys", MODE="0660", GROUP="users"

    # Firmware attributes (boot sound, panel overdrive)
    ACTION=="add", SUBSYSTEM=="firmware-attributes", KERNEL=="asus-armoury", RUN+="${chgrp} users /sys/class/firmware-attributes/asus-armoury/attributes/boot_sound/current_value", RUN+="${chmod} g+w /sys/class/firmware-attributes/asus-armoury/attributes/boot_sound/current_value"
    ACTION=="add", SUBSYSTEM=="firmware-attributes", KERNEL=="asus-armoury", RUN+="${chgrp} users /sys/class/firmware-attributes/asus-armoury/attributes/panel_overdrive/current_value", RUN+="${chmod} g+w /sys/class/firmware-attributes/asus-armoury/attributes/panel_overdrive/current_value"

    # hwmon fan curve attributes (scripts used for glob expansion over sysfs device path)
    ACTION=="add", SUBSYSTEM=="hwmon", ATTR{name}=="asus_custom_fan_curve", RUN+="${fanCurvePermsScript} %p"
    ACTION=="add", SUBSYSTEM=="hwmon", ATTR{name}=="asus", RUN+="${hwmonEnablePermsScript} %p"

    # asus-nb-wmi PPT power limit attributes (TDP control)
    ACTION=="add", SUBSYSTEM=="platform", KERNEL=="asus-nb-wmi", RUN+="${pptPermsScript}"

    # Keyboard backlight rules - main keyboard only
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/asus::kbd_backlight/brightness"

    # AC power change detection for keyboard backlight
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.bash}/bin/bash -c 'echo 3 > /sys/class/leds/asus::kbd_backlight/brightness'"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/leds/asus::kbd_backlight/brightness'"
  '';
}
