TODO:

- hostSpec

  - .domain
  - .networking
  - total rewrite of user handling, see EM's latest

- plasma-manager

  - generate existing config

- merge latest EM repo

- warnings during build:
  - evaluation warning: Skipping hindent because it is marked as broken.
  - evaluation warning: Skipping phpstan because it failed to evaluate.
```
  evaluation warning: The user 'jeff' has multiple of the options
                    `initialHashedPassword`, `hashedPassword`, `initialPassword`, `password`
                    & `hashedPasswordFile` set to a non-null value.

                    If multiple of these password options are set at the same time then a
                    specific order of precedence is followed, which can lead to surprising
                    results. The order of precedence differs depending on whether the
                    {option}`users.mutableUsers` option is set.

                    If the option {option}`users.mutableUsers` is
                    `false`, then the order of precedence is as shown
                    below, where values on the left are overridden by values on the right:
                    {option}`initialHashedPassword` -> {option}`hashedPassword` -> {option}`initialPassword` -> {option}`password` -> {option}`hashedPasswordFile`

                    The values of these options are:
                    * users.users."jeff".hashedPassword: "$y$j9T$7/v8iasDOCiVDbf59Msq41$uiTYFm7A5.2dUXipoO6fNnB2MCVLS7W2ZKN0YN1/m19"
                    * users.users."jeff".hashedPasswordFile: ""
                    * users.users."jeff".password: null
evaluation warning: The user 'root' has multiple of the options
                    `initialHashedPassword`, `hashedPassword`, `initialPassword`, `password`
                    & `hashedPasswordFile` set to a non-null value.

                    If multiple of these password options are set at the same time then a
                    specific order of precedence is followed, which can lead to surprising
                    results. The order of precedence differs depending on whether the
                    {option}`users.mutableUsers` option is set.

                    If the option {option}`users.mutableUsers` is
                    `false`, then the order of precedence is as shown
                    below, where values on the left are overridden by values on the right:
                    {option}`initialHashedPassword` -> {option}`hashedPassword` -> {option}`initialPassword` -> {option}`password` -> {option}`hashedPasswordFile`

                    The values of these options are:
                    * users.users."root".hashedPassword: "$y$j9T$7/v8iasDOCiVDbf59Msq41$uiTYFm7A5.2dUXipoO6fNnB2MCVLS7W2ZKN0YN1/m19"
                    * users.users."root".hashedPasswordFile: ""
                    * users.users."root".password: null
```
DONE

- ✅ pam ssh agent setup to not need to type in github passphrases

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

- minecraft
