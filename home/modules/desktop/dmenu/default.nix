{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.dmenu;
  theme = config.evertras.themes.selected;
  patchlib = import ./patches { };
  patchColor = patchlib.mkColorPatch { colors = theme.colors; };
in {
  options.evertras.home.desktop.dmenu = with lib; {
    enable = mkEnableOption "dmenu";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.dmenu.overrideAttrs (self: super: { patches = [ patchColor ]; }))
    ];
  };
}
