# TODO: opts is getting silly, make this better... but we
# want to make this a package, not a module, so how?
{ lib, pkgs, theme, opts }:
with lib;
let
  patch = (import ./patch.nix) { lib = lib; };
  makeCmd = cmd: ''"sh", "-c", "${strings.escape [ ''"'' ] cmd}", NULL,'';
  converted = map makeCmd opts.autostartCmds;
  autostartCmds = strings.concatStrings converted;
  basePatch = patch.mkBasePatch {
    autostartCmds = autostartCmds;
    borderpx = opts.borderpx;
    browser = opts.browser;
    colorBackground = theme.colors.background;
    colorPrimary = theme.colors.primary;
    colorText = theme.colors.text;
    fontName = theme.fonts.main.name;
    fontSize = opts.fontSize;
    gappx = opts.gappx;
    lock = opts.lock;
    modKey = opts.modKey;
    terminal = opts.terminal;
  };
  patchList = [ basePatch ];
in pkgs.dwm.overrideAttrs (self: super: {
  src = ./src;
  patches =
    if super.patches == null then patchList else super.patches ++ patchList;
})
