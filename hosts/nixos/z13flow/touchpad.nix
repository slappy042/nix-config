{ pkgs, ... }:
{
  # Enable libinput and configure touchpad
  services.libinput = {
    enable = true;
    touchpad = {
      disableWhileTyping = true;
      naturalScrolling = false;
      scrollMethod = "twofinger";
      tapping = true;
      tappingDragLock = true;
      accelProfile = "adaptive";
      accelSpeed = "0";
      leftHanded = false;
      middleEmulation = true;
      sendEventsMode = "enabled";
    };
  };

  # Additional touchpad packages that might help
  environment.systemPackages = with pkgs; [
    libinput # Input device management
    xorg.xinput # X input device configuration tool
    unstable.asusctl # ASUS laptop control utility for RGB, fans, etc. (from unstable)
    unstable.supergfxctl # GPU switching for ASUS laptops (from unstable)
  ];

  # Keyboard backlight and RGB configuration
  # Enable ASUS WMI platform driver for keyboard backlight control
  boot.kernelModules = [ "asus-wmi" ];

  # ASUS WMI kernel parameters for better keyboard backlight control
  boot.kernelParams = [
    "asus_wmi.fnlock_default=0" # Ensure Fn+F keys work for hardware controls
  ];

  # Enable asusctl service for RGB keyboard control (using unstable version)
  services.asusd = {
    enable = true;
    enableUserService = true;
    package = pkgs.unstable.asusctl;
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

  # Set RGB keyboard to steady color (white) at boot
  systemd.services.keyboard-rgb-default = {
    description = "Set RGB keyboard to steady white color";
    wantedBy = [ "multi-user.target" ];
    after = [ "asusd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.unstable.asusctl}/bin/asusctl aura static -c ffffff";
      RemainAfterExit = true;
    };
  };

  # Udev rules for Asus touchpads and keyboard backlight
  services.udev.extraRules = ''
    # Keyboard backlight rules - main keyboard only
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/asus::kbd_backlight/brightness"

    # AC power change detection for keyboard backlight
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.bash}/bin/bash -c 'echo 3 > /sys/class/leds/asus::kbd_backlight/brightness'"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/leds/asus::kbd_backlight/brightness'"

    # Asus touchpad fixes - ensure proper device classification
    # Asus touchpad fixes - ensure proper device classification
    SUBSYSTEM=="input", ATTRS{name}=="*ASUS*", ATTRS{name}=="*TouchPad*", ENV{LIBINPUT_IGNORE_DEVICE}="0", TAG+="libinput"
    SUBSYSTEM=="input", ATTRS{name}=="ASUSTeK Computer Inc. GZ302EA-Keyboard Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="0", TAG+="libinput"

    # Ensure touchscreen is properly identified (not confused with touchpad)
    SUBSYSTEM=="input", ATTRS{name}=="ELAN9008:00 04F3:43C7", ENV{ID_INPUT_TOUCHSCREEN}="1", ENV{ID_INPUT_TOUCHPAD}="0"

    # Force touchpad identification for the Asus device
    SUBSYSTEM=="input", ATTRS{name}=="ASUSTeK Computer Inc. GZ302EA-Keyboard Touchpad", ENV{ID_INPUT_TOUCHPAD}="1", ENV{ID_INPUT_MOUSE}="0"
  '';

  # X11 input class sections for better device recognition
  services.xserver.inputClassSections = [
    ''
      Identifier "Asus Touchpad"
      MatchProduct "ASUSTeK Computer Inc. GZ302EA-Keyboard Touchpad"
      Driver "libinput"
      Option "Tapping" "on"
      Option "TappingDrag" "on"
      Option "DisableWhileTyping" "on"
      Option "ScrollMethod" "twofinger"
      Option "NaturalScrolling" "false"
    ''
  ];
}
