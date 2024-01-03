# nix-systems

All my Nix systems.  Very much WIP and chaotic, intentionally doing things the
hard way to learn.

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
