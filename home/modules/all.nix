{ config, pkgs, ... }:

{
  # These are all controlled by enable flags
  imports = [
    ./core/core.nix
    ./bash/bash.nix
    ./editorconfig/editorconfig.nix
    ./kitty/kitty.nix
    ./starship/starship.nix
    ./tmux/tmux.nix
  ];
}
