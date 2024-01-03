{ ... }:

{
  # These are all controlled by enable flags
  imports = [
    ./bash
    ./core
    ./editorconfig
    ./git
    ./i3
    ./kitty
    ./starship
    ./theming
    ./tmux

    ../../themes/select.nix
  ];
}
