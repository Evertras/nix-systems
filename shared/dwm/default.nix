{ lib, pkgs, theme, opts }:
let
  patches = (import ./patches.nix) { lib = lib; };
  basePatch = patches.mkBasePatch {
    terminal = opts.terminal;
    lock = opts.lock;
    colorPrimary = theme.colors.primary;
    colorText = theme.colors.text;
    colorBackground = theme.colors.background;
    fontName = theme.fonts.main.name;
    fontSize = opts.fontSize;
    gappx = opts.gappx;
  };
  patchList = [ basePatch ];
in pkgs.dwm.overrideAttrs (self: super: {
  src = ./src;
  patches =
    if super.patches == null then patchList else super.patches ++ patchList;
})
