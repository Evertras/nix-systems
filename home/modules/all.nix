{ config, pkgs, ... }:

{
  # These are all controlled by enable flags
  imports = [
    ./bash/bash.nix
    ./core/core.nix
    ./editorconfig/editorconfig.nix
    ./kitty/kitty.nix
    ./starship/starship.nix
    ./theme/theme.nix
    ./tmux/tmux.nix
  ];
}
