{ lib, nerdfonts, pkgs, ... }:

let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  terminalFont = "FantasqueSansM";

  gpgKey = "11CB11BBC416774E";
in {
  #imports = [ ../../modules ../../../shared/themes/select.nix ];
  imports = [
    ../../modules/desktop/terminals/alacritty
    ../../modules/core
    ../../modules/shell

    ../../../shared/themes/select.nix
  ];

  evertras.themes.selected = (theme // {
    fonts = (theme.fonts // { terminal = nerdfonts.makeMono terminalFont; });
  });

  evertras.home = {
    core = {
      username = "brandon.fulljames";
      homeDirectory = "/Users/brandon.fulljames";
      usingNixOS = false;
    };

    desktop.terminals.alacritty.enable = true;
  };

  home = {
    # Other local things
    packages = with pkgs; [ ];

    file = { ".asdfrc".text = "legacy_version_file = yes"; };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };

  # https://github.com/nix-community/home-manager/issues/1341#issuecomment-778820334
  home.activation = {
    copyApplications = let
      apps = pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      };
    in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      baseDir="$HOME/Applications/Home Manager Apps"
      if [ -d "$baseDir" ]; then
        rm -rf "$baseDir"
      fi
      mkdir -p "$baseDir"
      for appFile in ${apps}/Applications/*; do
        target="$baseDir/$(basename "$appFile")"
        $DRY_RUN_CMD cp ''${VERBOSE_ARG:+-v} -fHRL "$appFile" "$baseDir"
        $DRY_RUN_CMD chmod ''${VERBOSE_ARG:+-v} -R +w "$target"
      done
    '';
  };
}
