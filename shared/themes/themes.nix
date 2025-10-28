{ lib, pkgs, ... }:
# Defines a bunch of constants for use in other
# modules to create a consistent theme that can be
# easily switched
with lib;
let
  palette = { catppuccin = import ./palette-catppuccin.nix; };

  nerdfonts = import ../nerdfonts { inherit pkgs; };

  catppuccinColors = [
    "Rosewater"
    "Flamingo"
    "Pink"
    "Mauve"
    "Red"
    "Maroon"
    "Peach"
    "Yellow"
    "Green"
    "Teal"
    "Sky"
    "Sapphire"
    "Blue"
    "Lavender"
  ];

  assertCatppuccinColor = color:
    lib.asserts.assertOneOf "catppuccin color" color catppuccinColors;

  defaults = {
    fonts = {
      main = nerdfonts.make "Terminess";
      mono = nerdfonts.makeMono "Terminess";
      desktop = nerdfonts.makeMono "CaskaydiaCove";
      terminal = nerdfonts.makeMono "Hasklug";
    };

    # For ideas: https://www.gnome-look.org/browse?cat=135&ord=rating
    # For names: use nix-find-theme-names
    # Fun ones to go back to:
    # orchis-theme / Orchis-Purple-Dark-Compact
    # catppuccin-gtk / (figure out overrides: https://github.com/catppuccin/gtk#for-nix-users)
    # matcha-gtk-theme / (Has good red / blue / green / seagreen)
    # layan-gtk-theme / Layan-Dark (nice purple)
    gtkTheme = {
      name = "Layan-Dark";
      package = pkgs.layan-gtk-theme;
    };

    # Fun ones to go back to:
    # weather-icons (not generally, but for niche uses?)
    iconTheme = {
      name = "Zafiro-icons-Dark";
      package = pkgs.zafiro-icons;
    };

    # For names: use nix-find-cursor-names
    # Fun ones to go back to:
    # nordzy-cursor-theme / Nordzy-cursors-white
    # bibata-cursors / Bibata-Modern-Ice
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
    };

    kittyTheme = "Catppuccin-Mocha";
    kittyOpacity = "0.8";
  };

  # https://github.com/catppuccin/cursors
  mkCatppuccinCursor = { color, flavor ? "Frappe" }: {
    _checkColor = assertCatppuccinColor color;
    name = "catppuccin-${toLower flavor}-${toLower color}-cursors";
    package = pkgs.catppuccin-cursors."${toLower flavor}${color}";
  };
in {
  mkCatppuccin = { color, flavor ? "Frappe" }:
    defaults // {
      _checkColor = assertCatppuccinColor color;

      colors = let p = palette.catppuccin.${flavor};
      in {
        primary = p.${color};
        highlight = p.highlight.${color};
        background = p.Base;
        backgroundDeep = p.Crust;
        text = p.Text;
        urgent = p.urgent.${color};
        contrast = p.contrast.${color};
        darker = p.darker.${color};
      };

      cursorTheme = mkCatppuccinCursor { inherit color flavor; };
    };
}
