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

    bgImage = cfg.bgImage;
  };
in {
  options.evertras.home.desktop.st = with lib; {
    enable = mkEnableOption "st";

    bgImage = mkOption {
      description = ''
        Path to background image.  Must be in farfeld (.ff),
        use jpg2ff or png2ff to convert.

        https://st.suckless.org/patches/background_image/
      '';
      type = types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = let patchList = [ mainPatch ];
    in [
      # To generate background images with jpg2ff and png2ff
      pkgs.farbfeld
      (pkgs.st.overrideAttrs (self: super: {
        src = ./src;
        patches = if super.patches == null then
          patchList
        else
          super.patches ++ patchList;
        buildInputs = super.buildInputs ++ [ pkgs.xorg.libXcursor ];
      }))
    ];
  };
}
