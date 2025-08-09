{ pkgs, ... }:
{
  # Enable libinput and configure touchpad
  services.xserver.libinput = {
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
  ];

  # Udev rules for Asus touchpads (if needed)
  services.udev.extraRules = ''
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
