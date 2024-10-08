{ }: {
  # Note to future self: be VERY careful about preserving
  # whitespace/tabs inside the actual strings...
  mkBasePatch = { autostartCmds, borderpx, browser, colorBackground
    , colorPrimary, colorText, fontName, fontSize, gappx, lock, modKey
    , swapFocusKey, terminal }:
    builtins.toFile "ever-dwm.diff" ''

      From 367332d7573337448e1efbc6ce94327543b3295f Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Thu, 1 Feb 2024 10:15:08 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h |  93 ++++++++++++++++++-------
       config.mk    |   2 +-
       drw.c        |   3 +-
       dwm.c        | 192 ++++++++++++++++++++++++++++++++++++++++++++++++---
       4 files changed, 253 insertions(+), 37 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 9efa774..12e4119 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -1,21 +1,29 @@
       /* See LICENSE file for copyright and license details. */
       
      +#include <X11/XF86keysym.h>
      +
       /* appearance */
      -static const unsigned int borderpx  = 1;        /* border pixel of windows */
      +static const unsigned int borderpx  = ${
        toString borderpx
      }; /* border pixel of windows */
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
      +	/*                fg              bg              border   */
      +	[SchemeNorm]  = { col_text,       col_background, col_primary },
      +	[SchemeSel]   = { col_background, col_primary,    col_primary },
      +	[SchemeTitle] = { col_primary,    col_background, col_primary },
      +};
      +
      +static const char *const autostart[] = {
      +	/* TODO: Make this configurable */
      +	"sh", "-c", "while true; do xsetroot -name \"$(date '+%a %m-%d %H:%M ')\"; sleep 1m; done", NULL,
      +	${autostartCmds}
      +	NULL /* terminate */
       };
       
       /* tagging */
      @@ -34,18 +42,19 @@ static const Rule rules[] = {
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
      +	{ "[|3",      tile },
      +	{ "vvv",      bstack },
       	{ "[M]",      monocle },
       };
       
       /* key definitions */
      -#define MODKEY Mod1Mask
      +#define MODKEY ${modKey}
       #define TAGKEYS(KEY,TAG) \
       	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
       	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
      @@ -55,10 +64,13 @@ static const Layout layouts[] = {
       /* helper for spawning shell commands in the pre dwm-5.0 fashion */
       #define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
       
      +/* helper for spawning simple commands */
      +#define CMD(cmd) { .v = (const char*[]){ cmd, NULL } }
      +
       /* commands */
       static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
      -static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
      -static const char *termcmd[]  = { "st", NULL };
      +static const char *dmenucmd[] = { "dmenu_run", NULL };
      +static const char *termcmd[]  = { "${terminal}", NULL };
       
       static const Key keys[] = {
       	/* modifier                     key        function        argument */
      @@ -71,14 +83,18 @@ static const Key keys[] = {
       	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
       	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
       	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
      -	{ MODKEY,                       XK_Return, zoom,           {0} },
      -	{ MODKEY,                       XK_Tab,    view,           {0} },
      -	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
      +	{ MODKEY,                       ${swapFocusKey}, zoom,     {0} },
      +	/*{ MODKEY,                       XK_Tab,    view,           {0} },*/
      +	/* Modified from shift+c */
      +	{ MODKEY,                       XK_q,      killclient,     {0} },
       	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
      -	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
      -	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
      -	{ MODKEY,                       XK_space,  setlayout,      {0} },
      -	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
      +	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[2]} },
      +	{ MODKEY,                       XK_u,      setlayout,      {.v = &layouts[1]} },
      +	/* Repurposed to match i3's mod+space to spawn terminal, moved
      +	   regular space to shift+space to allow layout toggles */
      +	/*{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },*/
      +	{ MODKEY|ShiftMask,             XK_space,  setlayout,      {0} },
      +	{ MODKEY,                       XK_space,  spawn,          {.v = termcmd } },
       	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
       	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
       	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
      @@ -95,6 +111,33 @@ static const Key keys[] = {
       	TAGKEYS(                        XK_8,                      7)
       	TAGKEYS(                        XK_9,                      8)
       	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
      +
      +	/* Media keys, make more configurable in the future - uses funcs installed
      +	   by nix in ~/.evertras/funcs, makes assumptions, but just want to get
      +	   this up and running before making it fancy. */
      +	{ 0,                       XF86XK_AudioLowerVolume,   spawn, CMD("/home/evertras/.evertras/funcs/volume-down") },
      +	{ 0,                       XF86XK_AudioRaiseVolume,   spawn, CMD("/home/evertras/.evertras/funcs/volume-up") },
      +	{ 0,                       XF86XK_AudioMute,          spawn, CMD("/home/evertras/.evertras/funcs/volume-mute-toggle") },
      +	{ 0,                       XF86XK_MonBrightnessUp,    spawn, CMD("/home/evertras/.evertras/funcs/brightness-up") },
      +	{ 0,                       XF86XK_MonBrightnessDown,  spawn, CMD("/home/evertras/.evertras/funcs/brightness-down") },
      +	/* Some other ideas for the future */
      +	/*
      +	{ 0,                       XF86XK_AudioPlay,          spawn, {.v = SHCMD("playerctl play-pause") } },
      +	{ 0,                       XF86XK_AudioNext,          spawn, {.v = SHCMD("playerctl next") } },
      +	{ 0,                       XF86XK_AudioPrev,          spawn, {.v = SHCMD("playerctl previous") } },
      +	{ 0,                       XF86XK_AudioStop,          spawn, {.v = SHCMD("playerctl stop") } },
      +	{ 0,                       XF86XK_AudioRewind,        spawn, {.v = SHCMD("playerctl position 10-") } },
      +	{ 0,                       XF86XK_AudioForward,       spawn, {.v = SHCMD("playerctl position 10+") } },
      +	{ 0,                       XF86XK_AudioMicMute,       spawn, {.v = SHCMD("pactl set-source-mute @DEFAULT_SOURCE@ toggle") } },
      +	{ 0,                       XF86XK_Display,            spawn, {.v = SHCMD("autorandr --change") } },
      +	{ 0,                       XF86XK_TouchpadToggle,     spawn, {.v = SHCMD("touchpad-toggle") } },
      +	{ 0,                       XF86XK_TouchpadOff,        spawn, {.v = SHCMD("touchpad-toggle off") } },
      +	{ 0,                       XF86XK_TouchpadOn,         spawn, {.v = SHCMD("touchpad-toggle on") } },
      +	*/
      +
      +	/* Additional keybinds added here */
      +	{ MODKEY,                       XK_Escape, spawn,          CMD("${lock}") },
      +	{ MODKEY,                       XK_r,      spawn,          CMD("${browser}") },
       };
       
       /* button definitions */
      @@ -102,7 +145,7 @@ static const Key keys[] = {
       static const Button buttons[] = {
       	/* click                event mask      button          function        argument */
       	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
      -	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
      +	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[1]} },
       	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
       	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
       	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
      diff --git a/config.mk b/config.mk
      index ba64d3d..5680345 100644
      --- a/config.mk
      +++ b/config.mk
      @@ -23,7 +23,7 @@ FREETYPEINC = /usr/include/freetype2
       
       # includes and libs
       INCS = -I''${X11INC} -I''${FREETYPEINC}
      -LIBS = -L''${X11LIB} -lX11 ''${XINERAMALIBS} ''${FREETYPELIBS}
      +LIBS = -L''${X11LIB} -lX11 ''${XINERAMALIBS} ''${FREETYPELIBS} -lXcursor
       
       # flags
       CPPFLAGS = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=700L -DVERSION=\"''${VERSION}\" ''${XINERAMAFLAGS}
      diff --git a/drw.c b/drw.c
      index a58a2b4..e62aff9 100644
      --- a/drw.c
      +++ b/drw.c
      @@ -4,6 +4,7 @@
       #include <string.h>
       #include <X11/Xlib.h>
       #include <X11/Xft/Xft.h>
      +#include <X11/Xcursor/Xcursor.h>
       
       #include "drw.h"
       #include "util.h"
      @@ -434,7 +435,7 @@ drw_cur_create(Drw *drw, int shape)
       	if (!drw || !(cur = ecalloc(1, sizeof(Cur))))
       		return NULL;
       
      -	cur->cursor = XCreateFontCursor(drw->dpy, shape);
      +	cur->cursor = XcursorLibraryLoadCursor(drw->dpy, "default");
       
       	return cur;
       }
      diff --git a/dwm.c b/dwm.c
      index f1d86b2..176228f 100644
      --- a/dwm.c
      +++ b/dwm.c
      @@ -20,6 +20,7 @@
        *
        * To understand everything else, start reading main().
        */
      +#include <assert.h>
       #include <errno.h>
       #include <locale.h>
       #include <signal.h>
      @@ -28,6 +29,8 @@
       #include <stdlib.h>
       #include <string.h>
       #include <unistd.h>
      +#include <libgen.h>
      +#include <sys/stat.h>
       #include <sys/types.h>
       #include <sys/wait.h>
       #include <X11/cursorfont.h>
      @@ -52,14 +55,14 @@
       #define ISVISIBLE(C)            ((C->tags & C->mon->tagset[C->mon->seltags]))
       #define LENGTH(X)               (sizeof X / sizeof X[0])
       #define MOUSEMASK               (BUTTONMASK|PointerMotionMask)
      -#define WIDTH(X)                ((X)->w + 2 * (X)->bw)
      -#define HEIGHT(X)               ((X)->h + 2 * (X)->bw)
      +#define WIDTH(X)                ((X)->w + 2 * (X)->bw + gappx)
      +#define HEIGHT(X)               ((X)->h + 2 * (X)->bw + gappx)
       #define TAGMASK                 ((1 << LENGTH(tags)) - 1)
       #define TEXTW(X)                (drw_fontset_getwidth(drw, (X)) + lrpad)
       
       /* enums */
       enum { CurNormal, CurResize, CurMove, CurLast }; /* cursor */
      -enum { SchemeNorm, SchemeSel }; /* color schemes */
      +enum { SchemeNorm, SchemeSel, SchemeTitle }; /* color schemes */
       enum { NetSupported, NetWMName, NetWMState, NetWMCheck,
              NetWMFullscreen, NetActiveWindow, NetWMWindowType,
              NetWMWindowTypeDialog, NetClientList, NetLast }; /* EWMH atoms */
      @@ -148,6 +151,9 @@ static void arrange(Monitor *m);
       static void arrangemon(Monitor *m);
       static void attach(Client *c);
       static void attachstack(Client *c);
      +static void autostart_exec(void);
      +static void bstack(Monitor *m);
      +static void bstackhoriz(Monitor *m);
       static void buttonpress(XEvent *e);
       static void checkotherwm(void);
       static void cleanup(void);
      @@ -274,6 +280,9 @@ static Window root, wmcheckwin;
       /* compile-time check if all tags fit into an unsigned int bit array. */
       struct NumTags { char limitexceeded[LENGTH(tags) > 31 ? -1 : 1]; };
       
      +static pid_t *autostart_pids;
      +static size_t autostart_len;
      +
       /* function implementations */
       void
       applyrules(Client *c)
      @@ -415,6 +424,91 @@ attachstack(Client *c)
       	c->mon->stack = c;
       }
       
      +static void
      +autostart_exec() {
      +	const char *const *p;
      +	size_t i = 0;
      +
      +	/* count entries */
      +	for (p = autostart; *p; autostart_len++, p++)
      +		while (*++p);
      +
      +	autostart_pids = malloc(autostart_len * sizeof(pid_t));
      +	for (p = autostart; *p; i++, p++) {
      +		if ((autostart_pids[i] = fork()) == 0) {
      +			setsid();
      +			execvp(*p, (char *const *)p);
      +			fprintf(stderr, "dwm: execvp %s\n", *p);
      +			perror(" failed");
      +			_exit(EXIT_FAILURE);
      +		}
      +		/* skip arguments */
      +		while (*++p);
      +	}
      +}
      +
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
      @@ -736,7 +830,7 @@ drawbar(Monitor *m)
       
       	if ((w = m->ww - tw - x) > bh) {
       		if (m->sel) {
      -			drw_setscheme(drw, scheme[m == selmon ? SchemeSel : SchemeNorm]);
      +			drw_setscheme(drw, scheme[m == selmon ? SchemeTitle : SchemeNorm]);
       			drw_text(drw, x, 0, w, bh, lrpad / 2, m->sel->name, 0);
       			if (m->sel->isfloating)
       				drw_rect(drw, x + boxs, boxs, boxw, boxw, m->sel->isfixed, 0);
      @@ -833,6 +927,8 @@ focusmon(const Arg *arg)
       	unfocus(selmon->sel, 0);
       	selmon = m;
       	focus(NULL);
      +	if (selmon->sel)
      +		XWarpPointer(dpy, None, selmon->sel->win, 0, 0, 0, 0, selmon->sel->w/2, selmon->sel->h/2);
       }
       
       void
      @@ -858,6 +954,7 @@ focusstack(const Arg *arg)
       	if (c) {
       		focus(c);
       		restack(selmon);
      +		XWarpPointer(dpy, None, c->win, 0, 0, 0, 0, c->w/2, c->h/2);
       	}
       }
       
      @@ -980,7 +1077,7 @@ grabkeys(void)
       void
       incnmaster(const Arg *arg)
       {
      -	selmon->nmaster = MAX(selmon->nmaster + arg->i, 0);
      +	selmon->nmaster = MAX(selmon->nmaster + arg->i, 1);
       	arrange(selmon);
       }
       
      @@ -1085,6 +1182,8 @@ manage(Window w, XWindowAttributes *wa)
       	c->mon->sel = c;
       	arrange(c->mon);
       	XMapWindow(dpy, c->win);
      +	if (c && c->mon == selmon)
      +		XWarpPointer(dpy, None, c->win, 0, 0, 0, 0, c->w/2, c->h/2);
       	focus(NULL);
       }
       
      @@ -1258,6 +1357,16 @@ propertynotify(XEvent *e)
       void
       quit(const Arg *arg)
       {
      +	size_t i;
      +
      +	/* kill child processes */
      +	for (i = 0; i < autostart_len; i++) {
      +		if (0 < autostart_pids[i]) {
      +			kill(autostart_pids[i], SIGTERM);
      +			waitpid(autostart_pids[i], NULL, 0);
      +		}
      +	}
      +
       	running = 0;
       }
       
      @@ -1286,12 +1395,37 @@ void
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
      @@ -1644,6 +1778,8 @@ showhide(Client *c)
       	}
       }
       
      +#define SPAWN_CWD_DELIM " []{}()<>\"':"
      +
       void
       spawn(const Arg *arg)
       {
      @@ -1654,6 +1790,39 @@ spawn(const Arg *arg)
       	if (fork() == 0) {
       		if (dpy)
       			close(ConnectionNumber(dpy));
      +		/* https://sunaku.github.io/dwm-spawn-cwd-patch.html */
      +		if(selmon->sel) {
      +			const char* const home = getenv("HOME");
      +			assert(home && strchr(home, '/'));
      +			const size_t homelen = strlen(home);
      +			char *cwd, *pathbuf = NULL;
      +			struct stat statbuf;
      +
      +			cwd = strtok(selmon->sel->name, SPAWN_CWD_DELIM);
      +			/* NOTE: strtok() alters selmon->sel->name in-place,
      +			 * but that does not matter because we are going to
      +			 * exec() below anyway; nothing else will use it */
      +			while(cwd) {
      +				if(*cwd == '~') { /* replace ~ with $HOME */
      +					if(!(pathbuf = malloc(homelen + strlen(cwd)))) /* ~ counts for NULL term */
      +						die("fatal: could not malloc() %u bytes\n", homelen + strlen(cwd));
      +					strcpy(strcpy(pathbuf, home) + homelen, cwd + 1);
      +					cwd = pathbuf;
      +				}
      +
      +				if(strchr(cwd, '/') && !stat(cwd, &statbuf)) {
      +					if(!S_ISDIR(statbuf.st_mode))
      +						cwd = dirname(cwd);
      +
      +					if(!chdir(cwd))
      +						break;
      +				}
      +
      +				cwd = strtok(NULL, SPAWN_CWD_DELIM);
      +			}
      +
      +			free(pathbuf);
      +		}
       		setsid();
       
       		sigemptyset(&sa.sa_mask);
      @@ -1701,7 +1870,7 @@ tile(Monitor *m)
       	for (i = my = ty = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), i++)
       		if (i < m->nmaster) {
       			h = (m->wh - my) / (MIN(n, m->nmaster) - i);
      -			resize(c, m->wx, m->wy + my, mw - (2*c->bw), h - (2*c->bw), 0);
      +			resize(c, m->wx, m->wy + my, mw - (2*c->bw) + (n > 1 ? gappx : 0), h - (2*c->bw), 0);
       			if (my + HEIGHT(c) < m->wh)
       				my += HEIGHT(c);
       		} else {
      @@ -1799,6 +1968,8 @@ unmanage(Client *c, int destroyed)
       	focus(NULL);
       	updateclientlist();
       	arrange(m);
      +	if (m == selmon && m->sel)
      +		XWarpPointer(dpy, None, m->sel->win, 0, 0, 0, 0, m->sel->w/2, m->sel->h/2);
       }
       
       void
      @@ -2152,6 +2323,7 @@ main(int argc, char *argv[])
       	if (!(dpy = XOpenDisplay(NULL)))
       		die("dwm: cannot open display");
       	checkotherwm();
      +	autostart_exec();
       	setup();
       #ifdef __OpenBSD__
       	if (pledge("stdio rpath proc exec", NULL) == -1)
      -- 
      2.42.0

    '';
}
