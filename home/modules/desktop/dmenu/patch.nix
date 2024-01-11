{ }: {
  mkPatch = { colors, fontName, fontSize }:
    builtins.toFile "dmenu-color-patch.diff" ''
      From 48a59b266c18258ac4e7d8ee9a83923787412e26 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Thu, 11 Jan 2024 22:08:19 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h | 8 ++++----
       1 file changed, 4 insertions(+), 4 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 1edb647..b8630b3 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -4,14 +4,14 @@
       static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
       /* -fn option overrides fonts[0]; default X11 font or font set */
       static const char *fonts[] = {
      -	"monospace:size=10"
      +	"${fontName}:size=${toString fontSize}"
       };
       static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
       static const char *colors[SchemeLast][2] = {
       	/*     fg         bg       */
      -	[SchemeNorm] = { "#bbbbbb", "#222222" },
      -	[SchemeSel] = { "#eeeeee", "#005577" },
      -	[SchemeOut] = { "#000000", "#00ffff" },
      +	[SchemeNorm] = { "${colors.text}", "${colors.background}" },
      +	[SchemeSel] = { "${colors.background}", "${colors.primary}" },
      +	[SchemeOut] = { "#ffff00", "#ff0000" },
       };
       /* -l option; if nonzero, dmenu uses vertical list with given number of lines */
       static unsigned int lines      = 0;
      -- 
      2.42.0
    '';
}
