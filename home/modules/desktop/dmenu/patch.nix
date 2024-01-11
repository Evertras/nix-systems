{ }: {
  mkPatch = { colors, fontName, fontSize }:
    builtins.toFile "dmenu-color-patch.diff" ''
      From 332199ae623b0fcb3ec8ddddab5099b30cd801f2 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Thu, 11 Jan 2024 22:24:40 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h | 8 ++++----
       dmenu.c      | 4 ++++
       2 files changed, 8 insertions(+), 4 deletions(-)

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
      diff --git a/dmenu.c b/dmenu.c
      index 40f93e0..8b81ce1 100644
      --- a/dmenu.c
      +++ b/dmenu.c
      @@ -761,6 +761,10 @@ main(int argc, char *argv[])
       		else
       			usage();
       
      +  if (prompt == NULL) {
      +    prompt = "run >";
      +  }
      +
       	if (!setlocale(LC_CTYPE, "") || !XSupportsLocale())
       		fputs("warning: no locale support\n", stderr);
       	if (!(dpy = XOpenDisplay(NULL)))
      -- 
      2.42.0
    '';
}
