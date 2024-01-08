# nix-systems

All my Nix systems and home-manager config.

![Sample screenshot](https://github.com/Evertras/nix-systems/assets/5923958/e56307ec-d4a5-4cfa-8ae9-492eefee684a)

## Using this

For regular system updates, just run `make system`.

For updating just home, run `make home` or just `make`.

For bootstrapping a fresh NixOS install as root:

```bash
nix-shell -p git gnumake
git clone https://github.com/Evertras/nix-systems
cd nix-systems
make system
# Specify actual desired user here
sudo -u evertras make home EVERTRAS_USER_PROFILE="some-profile-name"
# Set user profile here, direnv will use this later outside of root
cp .envrc.example .envrc
reboot now
```

### Troubleshooting

#### No suitable profile directory error message

```text
Could not find suitable profile directory, tried /home/evertras/.local/state/home-manager/profiles and /nix/var/nix/profiles/per-user/evertras
```

```bash
# The error message is misleading, make this directory
mkdir -p ~/.local/state/nix/profiles/
```

#### OpenGL issues when only using home

When running on a non-NixOS machine, problems may happen with openGL such as with Kitty:

```text

```

Use [nixGL](https://github.com/nix-community/nixGL) and install

## Short term todos

So I stop getting distracted by shiny things...

- Quick terminal controls (demo mode, opacity)

## Random todos for later

- Explore better [types](https://github.com/NixOS/nixpkgs/blob/master/lib/types.nix) like nonEmptyString
- Better null checks
- More enum checks with asserts for things like desktop as "i3"
