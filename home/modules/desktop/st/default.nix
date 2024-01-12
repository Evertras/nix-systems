{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.st;
  theme = config.evertras.themes.selected;
  patchlib = import ./patch.nix { };
  catppuccinPalette = import ../../../../shared/themes/palette-catppuccin.nix;
  colorsFrappe = catppuccinPalette.Frappe;
  mainPatch = patchlib.mkPatch {
    fontName = theme.fonts.terminal.name;
    fontSize = 22;
    # TODO: Can't use the shellBin that references pkgs here,
    # because toFile doesn't want to have dependencies to other
    # derivations.  The solution is to create a 'real' derivation here.
    # Leaving that for another day and just using fish here, fix later.
    shell = "fish";

    colors = {
      foreground = theme.colors.text;
      background = theme.colors.background;

      red = colorsFrappe.Red;
      green = colorsFrappe.Green;
      yellow = colorsFrappe.Yellow;
      blue = colorsFrappe.Blue;
      magenta = colorsFrappe.Mauve;
      cyan = colorsFrappe.Sky;
    };
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
