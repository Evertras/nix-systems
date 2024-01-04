{ lib, pkgs, ... }:
# Defines a bunch of constants for use in other
# modules to create a consistent theme that can be
# easily switched
with lib;
let
  palette = { catppuccin = import ./palette-catppuccin.nix; };

  defaults = {
    inspiration = "gradient";

    # Fun ones:
    # - CaskaydiaCove Nerd Font
    # - Terminess Nerd Font
    # - ComicShannsMono Nerd Font
    fonts = {
      main = { name = "Terminess Nerd Font"; };
      mono = { name = "Terminess Nerd Font Mono"; };
      desktop = { name = "CaskaydiaCove Nerd Font"; };
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

  # Rosewater, Flamingo, Pink, Mauve, Red, Maroon, Peach, Yellow,
  # Green, teal, Sky, Sapphire, Blue, Lavender, Dark, Light
  # https://github.com/catppuccin/cursors
  mkCatppuccinCursor = { color, flavor ? "Frappe" }: {
    name = "Catppuccin-${flavor}-${color}-Cursors";
    package = pkgs.catppuccin-cursors."${toLower flavor}${color}";
  };

  mkCatppuccinTheme = { color, flavor ? "Frappe" }: {
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
    };

    cursorTheme = mkCatppuccinCursor { inherit color; };

    gtkTheme = mkCatppuccinTheme { inherit color; };
  };

  mkCatppuccin = { color, flavor ? "Frappe" }:
    defaults // {
      inspiration = toLower color;

      colors = {
        primary = palette.catppuccin.${flavor}.${color};
        highlight = palette.catppuccin.${flavor}.${color};
        background = palette.catppuccin.${flavor}.Base;
        text = palette.catppuccin.${flavor}.Text;
        urgent = "#EF6F6C";
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
    };
  };
}
