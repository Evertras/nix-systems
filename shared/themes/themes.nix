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
    inspiration = "gradient";

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
    name = "Catppuccin-${flavor}-${color}-Cursors";
    package = pkgs.catppuccin-cursors."${toLower flavor}${color}";
  };

  mkCatppuccinTheme = { color, flavor ? "Frappe" }: {
    _checkColor = assertCatppuccinColor color;
    # https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/data/themes/catppuccin-gtk/default.nix
    name = "Catppuccin-${flavor}-Standard-${color}-Dark";
    package = pkgs.catppuccin-gtk.override {
      variant = toLower flavor;
      accents = [ (toLower color) ];
    };
  };
in {
  mint = let color = "Green";
  in defaults // {
    inspiration = "rainforest";

    # https://coolors.co/ef6f6c-2e394d-dcf9eb-59c9a5-7a907c
    colors = {
      primary = "#59C9A5";
      highlight = "#A7F1CD";
      background = "#2E394D";
      text = "#DCF9EB";
      urgent = "#EF6F6C";
      contrast = "#3F6FCC";
    };

    cursorTheme = mkCatppuccinCursor { inherit color; };

    gtkTheme = mkCatppuccinTheme { inherit color; };
  };

  mkCatppuccin = { color, flavor ? "Frappe" }:
    defaults // {
      _checkColor = assertCatppuccinColor color;

      inspiration = "hd ${palette.catppuccin.inspiration.${color}} wallpapers";

      colors = let p = palette.catppuccin.${flavor};
      in {
        primary = p.${color};
        highlight = p.highlight.${color};
        background = p.Base;
        text = p.Text;
        urgent = p.urgent.${color};
        contrast = p.contrast.${color};
      };

      cursorTheme = mkCatppuccinCursor { inherit color flavor; };

      gtkTheme = mkCatppuccinTheme { inherit color flavor; };
    };

  mountain = defaults // {
    inspiration = "mountain";

    colors = {
      primary = "#9A8493";
      highlight = "#E7D2C5";
      background = "#223843";
      text = "#EFF1F3";
      urgent = "#D2694B";
      contrast = "#3F6FCC";
    };
  };
}
