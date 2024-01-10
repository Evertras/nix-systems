{ lib }:
with lib; {
  # Note to future self: be VERY careful about preserving
  # whitespace/tabs inside the actual strings...
  mkBasePatch =
    { terminal, colorPrimary, colorText, colorBackground, fontSize, fontName }:
    builtins.toFile "dwm-base-patch.diff" ''

      From c669948b6ac5789ef56f29b99589781ae1202a26 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Wed, 10 Jan 2024 23:02:57 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h | 30 +++++++++++-------------
       dwm.c        | 64 ++++++++++++++++++++++++++++++++++++++++++++++++++++
       2 files changed, 77 insertions(+), 17 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 9efa774..36f66b7 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -5,17 +5,14 @@ static const unsigned int borderpx  = 1;        /* border pixel of windows */
       static const unsigned int snap      = 32;       /* snap pixel */
       static const int showbar            = 1;        /* 0 means no bar */
       static const int topbar             = 1;        /* 0 means bottom bar */
      -static const char *fonts[]          = { "monospace:size=10" };
      -static const char dmenufont[]       = "monospace:size=10";
      -static const char col_gray1[]       = "#222222";
      -static const char col_gray2[]       = "#444444";
      -static const char col_gray3[]       = "#bbbbbb";
      -static const char col_gray4[]       = "#eeeeee";
      -static const char col_cyan[]        = "#005577";
      +static const char *fonts[]          = { "${fontName}:size=${
        toString fontSize
      }" };
      +static const char col_background[]  = "${colorBackground}";
      +static const char col_text[]        = "${colorText}";
      +static const char col_primary[]     = "${colorPrimary}";
       static const char *colors[][3]      = {
      -	/*               fg         bg         border   */
      -	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
      -	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
      +	/*               fg              bg              border   */
      +	[SchemeNorm] = { col_text,       col_background, col_primary },
      +	[SchemeSel]  = { col_background, col_primary,    col_primary },
       };
       
       /* tagging */
      @@ -39,13 +36,13 @@ static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen win
       
       static const Layout layouts[] = {
       	/* symbol     arrange function */
      -	{ "[]=",      tile },    /* first entry is default */
      -	{ "><>",      NULL },    /* no layout function means floating behavior */
      +	{ "[|3",      tile },    /* first entry is default */
       	{ "[M]",      monocle },
      +	{ "vvv",      bstackhoriz },
       };
       
       /* key definitions */
      -#define MODKEY Mod1Mask
      +#define MODKEY Mod4Mask
       #define TAGKEYS(KEY,TAG) \
       	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
       	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
      @@ -57,8 +54,8 @@ static const Layout layouts[] = {
       
       /* commands */
       static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
      -static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
      -static const char *termcmd[]  = { "st", NULL };
      +static const char *dmenucmd[] = { "dmenu_run", NULL };
      +static const char *termcmd[]  = { "${terminal}", NULL };
       
       static const Key keys[] = {
       	/* modifier                     key        function        argument */
      @@ -76,7 +73,6 @@ static const Key keys[] = {
       	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
       	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
       	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
      -	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
       	{ MODKEY,                       XK_space,  setlayout,      {0} },
       	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
       	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
      @@ -102,7 +98,7 @@ static const Key keys[] = {
       static const Button buttons[] = {
       	/* click                event mask      button          function        argument */
       	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
      -	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
      +	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[1]} },
       	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
       	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
       	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
      diff --git a/dwm.c b/dwm.c
      index f1d86b2..5a974fa 100644
      --- a/dwm.c
      +++ b/dwm.c
      @@ -148,6 +148,8 @@ static void arrange(Monitor *m);
       static void arrangemon(Monitor *m);
       static void attach(Client *c);
       static void attachstack(Client *c);
      +static void bstack(Monitor *m);
      +static void bstackhoriz(Monitor *m);
       static void buttonpress(XEvent *e);
       static void checkotherwm(void);
       static void cleanup(void);
      @@ -415,6 +417,68 @@ attachstack(Client *c)
       	c->mon->stack = c;
       }
       
      +static void
      +bstack(Monitor *m) {
      +	int w, h, mh, mx, tx, ty, tw;
      +	unsigned int i, n;
      +	Client *c;
      +
      +	for (n = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), n++);
      +	if (n == 0)
      +		return;
      +	if (n > m->nmaster) {
      +		mh = m->nmaster ? m->mfact * m->wh : 0;
      +		tw = m->ww / (n - m->nmaster);
      +		ty = m->wy + mh;
      +	} else {
      +		mh = m->wh;
      +		tw = m->ww;
      +		ty = m->wy;
      +	}
      +	for (i = mx = 0, tx = m->wx, c = nexttiled(m->clients); c; c = nexttiled(c->next), i++) {
      +		if (i < m->nmaster) {
      +			w = (m->ww - mx) / (MIN(n, m->nmaster) - i);
      +			resize(c, m->wx + mx, m->wy, w - (2 * c->bw), mh - (2 * c->bw), 0);
      +			mx += WIDTH(c);
      +		} else {
      +			h = m->wh - mh;
      +			resize(c, tx, ty, tw - (2 * c->bw), h - (2 * c->bw), 0);
      +			if (tw != m->ww)
      +				tx += WIDTH(c);
      +		}
      +	}
      +}
      +
      +static void
      +bstackhoriz(Monitor *m) {
      +	int w, mh, mx, tx, ty, th;
      +	unsigned int i, n;
      +	Client *c;
      +
      +	for (n = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), n++);
      +	if (n == 0)
      +		return;
      +	if (n > m->nmaster) {
      +		mh = m->nmaster ? m->mfact * m->wh : 0;
      +		th = (m->wh - mh) / (n - m->nmaster);
      +		ty = m->wy + mh;
      +	} else {
      +		th = mh = m->wh;
      +		ty = m->wy;
      +	}
      +	for (i = mx = 0, tx = m->wx, c = nexttiled(m->clients); c; c = nexttiled(c->next), i++) {
      +		if (i < m->nmaster) {
      +			w = (m->ww - mx) / (MIN(n, m->nmaster) - i);
      +			resize(c, m->wx + mx, m->wy, w - (2 * c->bw), mh - (2 * c->bw), 0);
      +			mx += WIDTH(c);
      +		} else {
      +			resize(c, tx, ty, m->ww - (2 * c->bw), th - (2 * c->bw), 0);
      +			if (th != m->wh)
      +				ty += HEIGHT(c);
      +		}
      +	}
      +}
      +
       void
       buttonpress(XEvent *e)
       {
      -- 
      2.42.0

    '';
}
