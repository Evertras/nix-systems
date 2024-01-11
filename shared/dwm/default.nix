{ lib, pkgs, theme, opts ? { terminal = "kitty"; } }:
let
  patches = (import ./patches.nix) { lib = lib; };
  basePatch = patches.mkBasePatch {
    terminal = opts.terminal;
    colorPrimary = theme.colors.primary;
    colorText = theme.colors.text;
    colorBackground = theme.colors.background;
    fontName = theme.fonts.main.name;
    fontSize = 16;
    gappx = 15;
  };
  patchList = [ basePatch ];
in pkgs.dwm.overrideAttrs (self: super: {
  src = ./src;
  patches =
    if super.patches == null then patchList else super.patches ++ patchList;
})
