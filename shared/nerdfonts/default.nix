{ pkgs }:
let
  # https://search.nixos.org/packages?show=nerd-fonts.*
  # Figure out how to get the names better later...
  pkgMapping = {
    "CaskaydiaCove" = "caskaydia-cove";
    "Terminess" = "terminess-ttf";
  };
in {
  make = name: {
    name = "${name} Nerd Font";
    package = pkgs.nerd-fonts.${pkgMapping.${name}};
  };

  makeMono = name: {
    name = "${name} Nerd Font Mono";
    package = pkgs.nerd-fonts.${pkgMapping.${name}};
  };
}
