{ config, lib, nerdfonts, pkgs, ... }:

let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  terminalFontName = "FantasqueSansM";

  terminalFont = nerdfonts.makeMono terminalFontName;

  gpgKey = "11CB11BBC416774E";
in {
  #imports = [ ../../modules ../../../shared/themes/select.nix ];
  imports = [
    ../../modules/desktop/terminals
    ../../modules/core
    ../../modules/shell

    ../../../shared/themes/select.nix
  ];

  evertras.themes.selected =
    (theme // { fonts = (theme.fonts // { terminal = terminalFont; }); });

  evertras.home = {
    core = {
      username = "brandon.fulljames";
      homeDirectory = "/Users/brandon.fulljames";
      usingNixOS = false;
    };

    desktop.terminals.alacritty.enable = true;
    desktop.terminals.kitty.enable = true;
  };

  home = {
    # Other local things
    packages = with pkgs; [ terminalFont.package ];

    file = { ".asdfrc".text = "legacy_version_file = yes"; };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };

  # Reference for later
  #config = mkIf pkgs.stdenv.hostPlatform.isDarwin { ...

  # https://github.com/nix-community/home-manager/issues/1341#issuecomment-1870352014
  # Install MacOS applications to the user Applications folder. Also update Docked applications
  home.extraActivationPath = with pkgs; [ rsync dockutil gawk ];

  home.activation.trampolineApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${builtins.readFile ./sync-apps.sh}
    fromDir="$HOME/Applications/Home Manager Apps"
    toDir="$HOME/Applications/Home Manager Trampolines"
    sync_trampolines "$fromDir" "$toDir"
  '';
}
