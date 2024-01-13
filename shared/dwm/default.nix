{ lib, pkgs, theme, opts }:
let
  patches = (import ./patches.nix) { lib = lib; };
  basePatch = patches.mkBasePatch {
    colorBackground = theme.colors.background;
    colorPrimary = theme.colors.primary;
    colorText = theme.colors.text;
    fontName = theme.fonts.main.name;
    fontSize = opts.fontSize;
    gappx = opts.gappx;
    lock = opts.lock;
    terminal = opts.terminal;
  };
  patchList = [ basePatch ];
in pkgs.dwm.overrideAttrs (self: super: {
  src = ./src;
  patches =
    if super.patches == null then patchList else super.patches ++ patchList;
})
