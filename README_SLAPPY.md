# nix-config

This is "my" nix-config which is almost entirely lifted from [EmergentMind](https://github.com/EmergentMind/nix-config), minus the yubikey stuff and some other advanced configs that I don't know if I want/need.

## main structure

* Follow https://unmovedcentre.com/technology/2024/02/24/anatomy-of-a-nixos-config.html
* Git repo: [EmergentMind](https://github.com/EmergentMind/nix-config)

## changes to my fork

* remove cd-gitroot - doesn't seem useful
* grief -> dworkin.  Nix Dev VM
* user ta -> jeff.  Main user
* leave guppy/gusto stuff - maybe this will be useful to me someday (VM test lab for remote install, media machine)

## TODO

* ~~do sops setup~~
* ~~test out nixdev VM~~
* ~~disko setup for host~~
* split host default.nix into smaller pieces?
* erase your darlings / impermanence
* zfs disko setup for NAS
* copy .pub ssh keys alongside private keys
* fix .ssh/config not having id_camelot as IdentityFile as default
* nvim not installed? "vi" not working: "nvim is not found"

## Useful(?) links

* [NixOS Wiki](https://nixos.wiki/wiki/Main_Page)
* [source for main flake.nix and hosts structure](https://github.com/Electrostasy/dots/)
* [Wimpy's World](https://github.com/wimpysworld/nix-config)
* [Baby Steps with NixOS](https://seanrmurphy.medium.com/baby-steps-with-nixos-1ce7c4b0610)
  * first things to do after installing NixOS, like sshd, create user
* [Flake book](https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/inputs)


## Useful Commands

### Copy ISO to Proxmox

`scp /root/git/nix-config/result/iso/*.iso root@192.168.1.100:/var/lib/vz/template/iso`

### ssh-agent

```
eval "$(ssh-agent -s)"
ssh-add /root/.ssh/id_github_slappy
```

### Bootstrap command

```
nix develop
./scripts/bootstrap-nixos.sh -n dworkin -d 192.168.1.171 -k /root/.ssh/id_camelot
```

### git fork update
update my fork from upstream

```
git fetch upstream
git merge upstream/dev
```


# How to add a new host
- home/jeff/<host>.nix
- home/jeff/common/core/zsh alias
- nixos-installer/flake.nix
- flake.nix
