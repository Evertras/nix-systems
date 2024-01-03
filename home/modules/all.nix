{ config, pkgs, ... }:

{
  # These are all controlled by enable flags
  imports =
    [ ./bash ./core ./editorconfig ./i3 ./kitty ./starship ./theme ./tmux ];
}
