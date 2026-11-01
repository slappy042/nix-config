{ pkgs, ... }:
{
  # These touchpad options only apply to X11 sessions; on Wayland, KWin uses
  # Plasma's touchpad settings instead.
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

  environment.systemPackages = with pkgs; [
    xinput # X11 input device inspection/config
  ];

  services.udev.extraRules = ''
    # The keyboard cover also exposes a generic HID mouse node on the same USB
    # interface as the touchpad. libinput tags any USB/Bluetooth ID_INPUT_MOUSE
    # device as an "external mouse", so "Disable while mouse is connected"
    # always kept the touchpad off. Hide it from libinput.
    SUBSYSTEM=="input", ATTRS{name}=="ASUSTeK Computer Inc. GZ302EA-Keyboard Mouse", ENV{ID_INPUT_MOUSE}="", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';
}
