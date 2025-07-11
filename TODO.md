TODO:

hostSpec
.domain
.networking

- plasma-manager

  - generate existing config

- pam ssh agent setup to not need to type in github passphrases

- minecraft

DONE

- user creation removed - switched to primary instead

```
    #################### Users to Create ####################
    "hosts/common/users/jeff"
```

- these hardware lines

```
    #################### Hardware Modules ####################
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd
```

- check stateVersions of hosts

- fix UID in this file:
  hosts/common/optional/smbclient.nix
  use config.hostSpec somehow?

- Where does this go, from sops-jeff.nix?
  secrets = {
  "ssh_keys/camelot" = {
  path = "${homeDirectory}/.ssh/id_camelot";
  };
  };

- my git config stuff: goes in here: nix-config/home/jeff/common/optional/development/default.nix

- sops file: make sure ssh keys are written

- ssh config with keys, yubihosts, is weird

- nix-secrets:
  change ssh_keys/camelot to
  keys/ssh/camelot

- git commit signing

- vscode

  - setup sync

- brave

  - set as default
  - setup sync
