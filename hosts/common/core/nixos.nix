# Core functionality for every nixos host
{ config, lib, ... }:
let
  cfg = config.networking;
in
{
  # Database for aiding terminal-based programs
  environment.enableAllTerminfo = true;
  # Enable firmware with a license allowing redistribution
  hardware.enableRedistributableFirmware = true;

  # This should be handled by config.security.pam.sshAgentAuth.enable
  security.sudo.extraConfig = ''
    Defaults lecture = never # rollback results in sudo lectures after each reboot, it's somewhat useless anyway
    Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
    Defaults timestamp_timeout=120 # only ask for password every 2h
    # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
    Defaults env_keep+=SSH_AUTH_SOCK
  '';

  #
  # ========== Nix Helper ==========
  #
  # Provide better build output and will also handle garbage collection in place of standard nix gc (garbace collection)
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 20d --keep 20";
    flake = "/home/user/${config.hostSpec.home}/nix-config";
  };

  # this is to fix /bin/bash
  # it makes /bin appear empty, although it works fine
  # services.envfs.enable = true;

  # JEFF: I don't think I need this
  # services.keyd = {
  #   enable = true;
  #   keyboards.default = {
  #     ids = [ "*" ]; # Apply to all keyboards
  #     settings = {
  #       main = {
  #         capslock = "noop"; # TODO(keyboard): should change this to be overload(\, |) to match moonlander
  #         numlock = "noop"; # numlock state on by default via hyprland config
  #       };
  #     };
  #   };
  # };

  #
  # ========== Generation Label ==========
  #
  # Generation label (shown by supported bootloaders)
  system.nixos.label =
    let
      lbl = builtins.getEnv "GENERATION_LABEL";
    in
    if lbl != "" then lbl else config.hostSpec.hostName;

  #
  # ========== Localization ==========
  #
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # During activation, NM is stopped before NetworkManager-predefined-connections.service
  # is reloaded, causing `nmcli connection reload` to fail (NM not running). Disabling
  # reloadIfChanged makes activation restart the service instead (ExecStart=true), which
  # always succeeds. NM reloads connections fresh on its own restart anyway.
  systemd.services."NetworkManager-predefined-connections" = lib.mkIf cfg.networkmanager.enable {
    reloadIfChanged = lib.mkForce false;
  };
}
