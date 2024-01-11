{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.st;
  theme = config.evertras.themes.selected;
  patchlib = import ./patch.nix { };
  mainPatch = patchlib.mkPatch {
    fontName = theme.fonts.terminal.name;
    fontSize = 22;
    # TODO: Can't use the shellBin that references pkgs here,
    # because toFile doesn't want to have dependencies to other
    # derivations.  The solution is to create a 'real' derivation here.
    # Leaving that for another day and just using fish here, fix later.
    shell = "fish";
  };
in {
  options.evertras.home.desktop.st = with lib; {
    enable = mkEnableOption "st";
  };

  config = lib.mkIf cfg.enable {
    home.packages = let patchList = [ mainPatch ];
    in [
      (pkgs.st.overrideAttrs (self: super: {
        src = ./src;
        patches = if super.patches == null then
          patchList
        else
          super.patches ++ patchList;
      }))
    ];
  };
}
