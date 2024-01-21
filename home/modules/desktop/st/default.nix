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

    bgImage = if cfg.bgImage == "" then
      "${config.home.homeDirectory}/.evertras/backgrounds/wallpaper.ff"
    else
      cfg.bgImage;
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

    desktopResolution = mkOption {
      description = "The main desktop resolution, for background images";
      type = types.str;
      default = "2560x1440";
    };

    bgBlurPixels = mkOption {
      description = ''
        How many pixels to blur the background image by when generating.
        0 = no blur
      '';
      type = types.int;
      default = 0;
    };

    bgOpacityPercent100 = mkOption {
      description = ''
        Opacity level of generated backgrounds as a 0-100 value.

        Higher values are more opaque.
      '';

      type = types.int;
      default = 90;
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
          mkdir -p "$HOME/.evertras/backgrounds"
          target="$HOME/.evertras/backgrounds/wallpaper.ff"
          echo "No target given, defaulting to $target"
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

        if [ -f "$tmpName" ]; then
          echo "Removing old temp file: $tmpName"
          rm "$tmpName"
        fi

        echo "Converting $img -> $target"

        echo "Darkening/blurring..."
        convert "$img" \
          \( -size ${cfg.desktopResolution} "xc:${theme.colors.backgroundDeep}" \) \
          -resize ${cfg.desktopResolution} \
          -gaussian-blur 0x${toString cfg.bgBlurPixels} \
          -compose blend \
          -define compose:args=${toString cfg.bgOpacityPercent100} \
          -composite \
          "$tmpName"

        echo "Converting $img to farbfeld..."
        "$tool" < "$tmpName" > "$target"

        if [ ! -f "$target" ]; then
          echo "Failed to convert $img to farbfeld"
          exit 1
        fi
      '';

      gen-st-bg-stylish.body = ''
        mkdir -p "$HOME/.evertras/backgrounds"
        gen-st-bg "$HOME/.cache/styli.sh/wallpaper.jpg" "$HOME/.evertras/backgrounds/wallpaper.ff"
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
