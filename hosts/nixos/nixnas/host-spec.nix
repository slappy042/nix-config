{ ... }:
{
  hostSpec = {
    hostName = "nixnas";
    persistFolder = "/persist"; # added for "completion" because of the disko spec that was used even though impermanence isn't actually enabled here yet.
  };
}
