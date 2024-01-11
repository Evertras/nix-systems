{ lib }:
with lib; {
  # Note to future self: be VERY careful about preserving
  # whitespace/tabs inside the actual strings...
  mkBasePatch = { terminal, colorPrimary, colorText, colorBackground, fontSize
    , fontName, gappx }:
    builtins.toFile "dwm-base-patch.diff" ''

      From 6bb9b0582744d4e011cc164b2f52042574c72b6a Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Thu, 11 Jan 2024 21:08:52 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h |  38 +++++++++----------
       dwm.c        | 103 +++++++++++++++++++++++++++++++++++++++++++++++----
       2 files changed, 115 insertions(+), 26 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 9efa774..180207f 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -3,19 +3,17 @@
       /* appearance */
       static const unsigned int borderpx  = 1;        /* border pixel of windows */
       static const unsigned int snap      = 32;       /* snap pixel */
      +static const unsigned int gappx     = ${
        toString gappx
      }; /* gaps between windows */
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
      @@ -34,18 +32,19 @@ static const Rule rules[] = {
       /* layout(s) */
       static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
       static const int nmaster     = 1;    /* number of clients in master area */
      -static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
      +static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
       static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
       
       static const Layout layouts[] = {
      +    /* first entry is default */
       	/* symbol     arrange function */
      -	{ "[]=",      tile },    /* first entry is default */
      -	{ "><>",      NULL },    /* no layout function means floating behavior */
      +	{ "vvv",      bstack },
       	{ "[M]",      monocle },
      +	{ "[|3",      tile },
       };
       
       /* key definitions */
      -#define MODKEY Mod1Mask
      +#define MODKEY Mod4Mask
       #define TAGKEYS(KEY,TAG) \
       	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
       	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
      @@ -57,8 +56,8 @@ static const Layout layouts[] = {
       
       /* commands */
       static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
      -static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
      -static const char *termcmd[]  = { "st", NULL };
      +static const char *dmenucmd[] = { "dmenu_run", NULL };
      +static const char *termcmd[]  = { "${terminal}", NULL };
       
       static const Key keys[] = {
       	/* modifier                     key        function        argument */
      @@ -73,10 +72,11 @@ static const Key keys[] = {
       	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
       	{ MODKEY,                       XK_Return, zoom,           {0} },
       	{ MODKEY,                       XK_Tab,    view,           {0} },
      -	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
      +	/* Modified from shift+c */
      +	{ MODKEY,                       XK_q,      killclient,     {0} },
       	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
       	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
      -	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
      +	{ MODKEY,                       XK_u,      setlayout,      {.v = &layouts[2]} },
       	{ MODKEY,                       XK_space,  setlayout,      {0} },
       	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
       	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
      @@ -102,7 +102,7 @@ static const Key keys[] = {
       static const Button buttons[] = {
       	/* click                event mask      button          function        argument */
       	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
      -	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
      +	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[1]} },
       	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
       	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
       	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
      diff --git a/dwm.c b/dwm.c
      index f1d86b2..abe6a3c 100644
      --- a/dwm.c
      +++ b/dwm.c
      @@ -52,8 +52,8 @@
       #define ISVISIBLE(C)            ((C->tags & C->mon->tagset[C->mon->seltags]))
       #define LENGTH(X)               (sizeof X / sizeof X[0])
       #define MOUSEMASK               (BUTTONMASK|PointerMotionMask)
      -#define WIDTH(X)                ((X)->w + 2 * (X)->bw)
      -#define HEIGHT(X)               ((X)->h + 2 * (X)->bw)
      +#define WIDTH(X)                ((X)->w + 2 * (X)->bw + gappx)
      +#define HEIGHT(X)               ((X)->h + 2 * (X)->bw + gappx)
       #define TAGMASK                 ((1 << LENGTH(tags)) - 1)
       #define TEXTW(X)                (drw_fontset_getwidth(drw, (X)) + lrpad)
       
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
       
      +void
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
      +void
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
      @@ -1286,12 +1350,37 @@ void
       resizeclient(Client *c, int x, int y, int w, int h)
       {
       	XWindowChanges wc;
      +	unsigned int n;
      +	unsigned int gapoffset;
      +	unsigned int gapincr;
      +	Client *nbc;
       
      -	c->oldx = c->x; c->x = wc.x = x;
      -	c->oldy = c->y; c->y = wc.y = y;
      -	c->oldw = c->w; c->w = wc.width = w;
      -	c->oldh = c->h; c->h = wc.height = h;
       	wc.border_width = c->bw;
      +
      +	/* Get number of clients for the client's monitor */
      +	for (n = 0, nbc = nexttiled(c->mon->clients); nbc; nbc = nexttiled(nbc->next), n++);
      +
      +	/* Do nothing if layout is floating */
      +	if (c->isfloating || c->mon->lt[c->mon->sellt]->arrange == NULL) {
      +		gapincr = gapoffset = 0;
      +	} else {
      +		/* Remove border and gap if layout is monocle or only one client */
      +		if (c->mon->lt[c->mon->sellt]->arrange == monocle || n == 1) {
      +			gapoffset = 0;
      +			gapincr = -2 * borderpx;
      +			wc.border_width = 0;
      +		} else {
      +			gapoffset = gappx;
      +			gapincr = 2 * gappx;
      +		}
      +	}
      +
      +	c->oldx = c->x; c->x = wc.x = x + gapoffset;
      +	c->oldy = c->y; c->y = wc.y = y + gapoffset;
      +	c->oldw = c->w; c->w = wc.width = w - gapincr;
      +	c->oldh = c->h; c->h = wc.height = h - gapincr;
      +
      +
       	XConfigureWindow(dpy, c->win, CWX|CWY|CWWidth|CWHeight|CWBorderWidth, &wc);
       	configure(c);
       	XSync(dpy, False);
      @@ -1701,7 +1790,7 @@ tile(Monitor *m)
       	for (i = my = ty = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), i++)
       		if (i < m->nmaster) {
       			h = (m->wh - my) / (MIN(n, m->nmaster) - i);
      -			resize(c, m->wx, m->wy + my, mw - (2*c->bw), h - (2*c->bw), 0);
      +			resize(c, m->wx, m->wy + my, mw - (2*c->bw) + (n > 1 ? gappx : 0), h - (2*c->bw), 0);
       			if (my + HEIGHT(c) < m->wh)
       				my += HEIGHT(c);
       		} else {
      -- 
      2.42.0

    '';
}
