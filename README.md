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

When running on a non-NixOS machine, problems may happen with OpenGL such as with Kitty.

Use [nixGL](https://github.com/nix-community/nixGL) to get around this.

```bash
nixGL kitty
```

## Short term todos

So I stop getting distracted by shiny things...

- Quick terminal controls (demo mode, opacity)

## Random todos for later

- Explore better [types](https://github.com/NixOS/nixpkgs/blob/master/lib/types.nix) like nonEmptyString
- Better null checks
- More enum checks with asserts for things like desktop as "i3"
- Better config between window managers on a full NixOS system, currently need to enable twice for i3 config

## Font list

I get bored with fonts so here's a list of the nerd fonts
that I actually like, as a reminder to myself.

### Clean

For just focusing.

#### Standard

Go-tos

- CaskaydiaCove - Solid baseline when all else fails, bit wider
- Hasklug - Default go-to for ligatures, clean

#### Alternatives

Feeling different but still "boring".

- AurulentSansM - Soft/clean, not sure if I like 0 without dot
- BitstromWera - Clean/simple
- CodeNewRoman - Clean/simple
- Cousine - Clear, simple
- JetBrainsMono - Clean, ligatures
- Literation - Wider
- OverpassM - Thinner, simple
- RobotoMono - Clean, simple
- UbuntuMono - Feels like Ubuntu, yep

### Fun/different

To change it up.

- Agave Nerd - kind of old school sharp feel
- ComicShannsMono - Casual and surprisingly nice to read
- Gohu Font 14 - Pixel font, sharp at size 14 - can use 11 as well for tiny readable font
- Hurmit - Fun change in small doses
- Iosevka - Feels squished horizontally but still clean
- Monofur - Thin stroke with round characters
- Monoid - Bigger, but ligatures
- Mononoki - Just feels different, hard to describe
- OpenDyslexicM - Weirdly stroked characters, wider
- ProFont IIx - Pixel font, nicely sharp
- ProggyClean - Works for very small font sizes, not great at larger
- ShureTechMono - Bit squished, hard to describe
- SpaceMono - Extra space between lines
- Terminess - Works nicely for windows/titles but not so much terminal
