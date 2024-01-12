{ config, lib, pkgs, ... }:

let
  cfg = config.evertras.home.desktop.st;
  theme = config.evertras.themes.selected;
  patchlib = import ./patch.nix { };
  catppuccinPalette = import ../../../../shared/themes/palette-catppuccin.nix;
  colorsFrappe = catppuccinPalette.Frappe;
  mainPatch = patchlib.mkPatch {
    fontName = theme.fonts.terminal.name;
    fontSize = cfg.fontSize;

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

    fontSize = mkOption {
      description = ''
        Font size to use.
      '';
      type = types.int;
      default = 22;
    };
  };

  config = lib.mkIf cfg.enable {
    evertras.home.shell.funcs = {
      gen-st-bg.body = ''
        set -e

        if [ -z "$1" ]; then
          echo "Usage: gen-st-bg <base-image> [target]"
          echo "  base-image: Image to use as a base"
          echo "  target:     Output file (defaults to <base-image>.ff)"
          exit 1
        fi

        img="$1"
        target="$2"

        if [ ! -f "$img" ]; then
          echo "File not found: $img"
          exit 1
        fi

        if [ -z "$target" ]; then
          target="$img.ff"
        fi

        if [ "$(file -b --mime-type "$img")" = "image/jpeg" ]; then
          tool="jpg2ff"
          tmpName=/tmp/altered.jpg
        elif [ "$(file -b --mime-type "$img")" = "image/png" ]; then
          tool="png2ff"
          tmpName=/tmp/altered.png
        else
          echo "Unsupported image type (jpg/png): $img"
          exit 1
        fi

        echo "Darkening/blurring..."
        convert "$img" -fill black -colorize 80% -gaussian-blur 0x8 -resize 2560x1440 "$tmpName"

        echo "Converting $img to farbfeld..."
        "$tool" < "$tmpName" > "$target"

        if [ ! -f "$target" ]; then
          echo "Failed to convert $img to farbfeld"
          exit 1
        fi
      '';
    };
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
