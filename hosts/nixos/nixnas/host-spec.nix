{ lib, ... }:
{
  hostSpec = {
    hostName = "nixnas";
    users = lib.mkForce [
      "jeff"
    ];

    persistFolder = "/persist"; # added for "completion" because of the disko spec that was used even though impermanence isn't actually enabled here yet.
  };
}
