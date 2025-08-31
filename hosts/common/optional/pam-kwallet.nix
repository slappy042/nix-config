# PAM configuration to automatically unlock KWallet and SSH keys on login
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Enable PAM kwallet integration
  security.pam.services = {
    login.enableKwallet = true;
    sddm.enableKwallet = true;
    sddm-greeter.enableKwallet = true;

    # For SSH agent integration
    sudo.text = lib.mkAfter ''
      session optional ${pkgs.kdePackages.kwallet-pam}/lib/security/pam_kwallet5.so
    '';
  };

  # Ensure kwallet-pam is installed system-wide
  environment.systemPackages = with pkgs; [
    kdePackages.kwallet-pam
    kdePackages.kwalletmanager
  ];

  # Enable SSH agent auth for sudo (optional but recommended)
  security.pam.sshAgentAuth.enable = true;
}
