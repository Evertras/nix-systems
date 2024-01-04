# nix-systems

All my Nix systems and home-manager config.

## Using this

For regular system updates, just run `make system`.

For updating just home, run `make home` or just `make`.

For bootstrapping a fresh NixOS install as root:

```bash
nix-shell -p git gnumake
git clone https://github.com/Evertras/nix-systems
cd nix-systems
make system
sudo -u evertras make home
reboot now
```

## Random todos for later

- Explore better [types](https://github.com/NixOS/nixpkgs/blob/master/lib/types.nix) like nonEmptyString
- Better null checks
- Enum checks with asserts for things like desktop as "i3"
- Different user variants and a good way to select them (direnv?)
- Fix themes file to include actual packages, check [this file](https://github.com/nix-community/nixvim/blob/10d114f5a6e0a9591d13a28a92905e71cc100b39/lib/helpers.nix) for some ideas
