{ }: {
  mkPatch = { colors, fontName, fontSize, lineHeight }:
    builtins.toFile "dmenu-color-patch.diff" ''

      From 14a496b22954768392a4b5f426f2ab29564977f3 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Fri, 12 Jan 2024 00:31:15 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h | 11 +++++++----
       dmenu.1      |  5 +++++
       dmenu.c      | 15 ++++++++++++---
       3 files changed, 24 insertions(+), 7 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 1edb647..dc70eb3 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -4,17 +4,20 @@
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
      +/* -h option; minimum height of a menu line */
      +static unsigned int lineheight = ${toString lineHeight};
      +static unsigned int min_lineheight = 8;
       
       /*
        * Characters not considered part of a word while deleting words
      diff --git a/dmenu.1 b/dmenu.1
      index 323f93c..f2a82b4 100644
      --- a/dmenu.1
      +++ b/dmenu.1
      @@ -6,6 +6,8 @@ dmenu \- dynamic menu
       .RB [ \-bfiv ]
       .RB [ \-l
       .IR lines ]
      +.RB [ \-h
      +.IR height ]
       .RB [ \-m
       .IR monitor ]
       .RB [ \-p
      @@ -50,6 +52,9 @@ dmenu matches menu items case insensitively.
       .BI \-l " lines"
       dmenu lists items vertically, with the given number of lines.
       .TP
      +.BI \-h " height"
      +dmenu uses a menu line of at least 'height' pixels tall, but no less than 8.
      +.TP
       .BI \-m " monitor"
       dmenu is displayed on the monitor number supplied. Monitor numbers are starting
       from 0.
      diff --git a/dmenu.c b/dmenu.c
      index 40f93e0..2134512 100644
      --- a/dmenu.c
      +++ b/dmenu.c
      @@ -147,7 +147,7 @@ drawmenu(void)
       {
       	unsigned int curpos;
       	struct item *item;
      -	int x = 0, y = 0, w;
      +	int x = 0, y = 0, fh = drw->fonts->h, w;
       
       	drw_setscheme(drw, scheme[SchemeNorm]);
       	drw_rect(drw, 0, 0, mw, mh, 1, 1);
      @@ -164,7 +164,7 @@ drawmenu(void)
       	curpos = TEXTW(text) - TEXTW(&text[cursor]);
       	if ((curpos += lrpad / 2 - 1) < w) {
       		drw_setscheme(drw, scheme[SchemeNorm]);
      -		drw_rect(drw, x + curpos, 2, 2, bh - 4, 1, 0);
      +		drw_rect(drw, x + curpos, 2 + (bh - fh) / 2, 2, fh - 4, 1, 0);
       	}
       
       	if (lines > 0) {
      @@ -634,6 +634,7 @@ setup(void)
       
       	/* calculate menu geometry */
       	bh = drw->fonts->h + 2;
      +	bh = MAX(bh,lineheight);	/* make a menu line AT LEAST 'lineheight' tall */
       	lines = MAX(lines, 0);
       	mh = (lines + 1) * bh;
       #ifdef XINERAMA
      @@ -715,7 +716,7 @@ setup(void)
       static void
       usage(void)
       {
      -	die("usage: dmenu [-bfiv] [-l lines] [-p prompt] [-fn font] [-m monitor]\n"
      +	die("usage: dmenu [-bfiv] [-l lines] [-h height] [-p prompt] [-fn font] [-m monitor]\n"
       	    "             [-nb color] [-nf color] [-sb color] [-sf color] [-w windowid]");
       }
       
      @@ -742,6 +743,10 @@ main(int argc, char *argv[])
       		/* these options take one argument */
       		else if (!strcmp(argv[i], "-l"))   /* number of lines in vertical list */
       			lines = atoi(argv[++i]);
      +		else if (!strcmp(argv[i], "-h")) { /* minimum height of one menu line */
      +			lineheight = atoi(argv[++i]);
      +			lineheight = MAX(lineheight, min_lineheight);
      +		}
       		else if (!strcmp(argv[i], "-m"))
       			mon = atoi(argv[++i]);
       		else if (!strcmp(argv[i], "-p"))   /* adds prompt to left of input field */
      @@ -761,6 +766,10 @@ main(int argc, char *argv[])
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
