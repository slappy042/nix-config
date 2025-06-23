{ config, ... }:
{

  # Set a temp password for use by minimal builds like installer and iso
  users.users.${config.hostSpec.username} = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$7/v8iasDOCiVDbf59Msq41$uiTYFm7A5.2dUXipoO6fNnB2MCVLS7W2ZKN0YN1/m19";
    extraGroups = [ "wheel" ];
  };
}
