{ }: {
  mkPatch = { fontName, fontSize, colors, bgImage }:

    builtins.toFile "ever-st.diff" ''

      From 3d4eee8af9ec776aec9f942790190ba8e1926199 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Fri, 12 Jan 2024 22:33:16 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h |  32 +++---
       config.mk    |   2 +-
       st.h         |   6 ++
       x.c          | 293 ++++++++++++++++++++++++++++++++++-----------------
       4 files changed, 224 insertions(+), 109 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 91ab8ca..88b492c 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -5,9 +5,17 @@
        *
        * font: see http://freedesktop.org/software/fontconfig/fontconfig-user.html
        */
      -static char *font = "Liberation Mono:pixelsize=12:antialias=true:autohint=true";
      +static char *font = "${fontName}:pixelsize=${
        toString fontSize
      }:antialias=true:autohint=true";
       static int borderpx = 2;
       
      +/*
      + * background image
      + * expects farbfeld format
      + * pseudo transparency fixes coordinates to the screen origin
      + */
      +static const char *bgfile = "${bgImage}";
      +static const int pseudotransparency = 1;
      +
       /*
        * What program is execed by st depends of these precedence rules:
        * 1: program passed with -e
      @@ -97,12 +105,12 @@ unsigned int tabspaces = 8;
       static const char *colorname[] = {
       	/* 8 normal colors */
       	"black",
      -	"red3",
      -	"green3",
      -	"yellow3",
      -	"blue2",
      -	"magenta3",
      -	"cyan3",
      +	"${colors.red}",
      +	"${colors.green}",
      +	"${colors.yellow}",
      +	"${colors.blue}",
      +	"${colors.magenta}",
      +	"${colors.cyan}",
       	"gray90",
       
       	/* 8 bright colors */
      @@ -120,8 +128,8 @@ static const char *colorname[] = {
       	/* more colors can be added after 255 to use with DefaultXX */
       	"#cccccc",
       	"#555555",
      -	"gray90", /* default foreground colour */
      -	"black", /* default background colour */
      +	"${colors.foreground}", /* default foreground colour */
      +	"${colors.background}", /* default background colour */
       };
       
       
      @@ -151,11 +159,9 @@ static unsigned int cols = 80;
       static unsigned int rows = 24;
       
       /*
      - * Default colour and shape of the mouse cursor
      + * Default shape of the mouse cursor
        */
      -static unsigned int mouseshape = XC_xterm;
      -static unsigned int mousefg = 7;
      -static unsigned int mousebg = 0;
      +static char* mouseshape = "default";
       
       /*
        * Color used to display font attributes when fontconfig selected a font which
      diff --git a/config.mk b/config.mk
      index 1e306f8..2bbc6be 100644
      --- a/config.mk
      +++ b/config.mk
      @@ -16,7 +16,7 @@ PKG_CONFIG = pkg-config
       INCS = -I$(X11INC) \
              `$(PKG_CONFIG) --cflags fontconfig` \
              `$(PKG_CONFIG) --cflags freetype2`
      -LIBS = -L$(X11LIB) -lm -lrt -lX11 -lutil -lXft \
      +LIBS = -L$(X11LIB) -lm -lrt -lX11 -lutil -lXft -lXcursor \
              `$(PKG_CONFIG) --libs fontconfig` \
              `$(PKG_CONFIG) --libs freetype2`
       
      diff --git a/st.h b/st.h
      index fd3b0d8..19d81b0 100644
      --- a/st.h
      +++ b/st.h
      @@ -36,6 +36,12 @@ enum glyph_attribute {
       	ATTR_BOLD_FAINT = ATTR_BOLD | ATTR_FAINT,
       };
       
      +enum drawing_mode {
      +	DRAW_NONE = 0,
      +	DRAW_BG = 1 << 0,
      +	DRAW_FG = 1 << 1,
      +};
      +
       enum selection_mode {
       	SEL_IDLE = 0,
       	SEL_EMPTY = 1,
      diff --git a/x.c b/x.c
      index b36fb8c..3953a83 100644
      --- a/x.c
      +++ b/x.c
      @@ -14,6 +14,8 @@
       #include <X11/keysym.h>
       #include <X11/Xft/Xft.h>
       #include <X11/XKBlib.h>
      +#include <X11/Xcursor/Xcursor.h>
      +#include <arpa/inet.h>
       
       char *argv0;
       #include "arg.h"
      @@ -81,6 +83,7 @@ typedef XftGlyphFontSpec GlyphFontSpec;
       typedef struct {
       	int tw, th; /* tty width and height */
       	int w, h; /* window width and height */
      +	int x, y; /* window location */
       	int ch; /* char height */
       	int cw; /* char width  */
       	int mode; /* window state/mode flags */
      @@ -101,6 +104,7 @@ typedef struct {
       		XVaNestedList spotlist;
       	} ime;
       	Draw draw;
      +	GC bggc; /* Graphics Context for background */
       	Visual *vis;
       	XSetWindowAttributes attrs;
       	int scr;
      @@ -142,7 +146,7 @@ typedef struct {
       
       static inline ushort sixd_to_16bit(int);
       static int xmakeglyphfontspecs(XftGlyphFontSpec *, const Glyph *, int, int, int);
      -static void xdrawglyphfontspecs(const XftGlyphFontSpec *, Glyph, int, int, int);
      +static void xdrawglyphfontspecs(const XftGlyphFontSpec *, Glyph, int, int, int, int);
       static void xdrawglyph(Glyph, int, int);
       static void xclear(int, int, int, int);
       static int xgeommasktogravity(int);
      @@ -151,6 +155,9 @@ static void ximinstantiate(Display *, XPointer, XPointer);
       static void ximdestroy(XIM, XPointer, XPointer);
       static int xicdestroy(XIC, XPointer, XPointer);
       static void xinit(int, int);
      +static void updatexy(void);
      +static XImage *loadff(const char*);
      +static void bginit();
       static void cresize(int, int);
       static void xresize(int, int);
       static void xhints(void);
      @@ -515,6 +522,12 @@ propnotify(XEvent *e)
       			 xpev->atom == clipboard)) {
       		selnotify(e);
       	}
      +
      +	if (pseudotransparency &&
      +			!strncmp(XGetAtomName(xw.dpy, e->xproperty.atom), "_NET_WM_STATE", 13)) {
      +		updatexy();
      +		redraw();
      +	}
       }
       
       void
      @@ -545,16 +558,19 @@ selnotify(XEvent *e)
       			return;
       		}
       
      -		if (e->type == PropertyNotify && nitems == 0 && rem == 0) {
      +		if (e->type == PropertyNotify && nitems == 0 && rem == 0 &&
      +				!pseudotransparency) {
       			/*
       			 * If there is some PropertyNotify with no data, then
       			 * this is the signal of the selection owner that all
       			 * data has been transferred. We won't need to receive
       			 * PropertyNotify events anymore.
       			 */
      -			MODBIT(xw.attrs.event_mask, 0, PropertyChangeMask);
      -			XChangeWindowAttributes(xw.dpy, xw.win, CWEventMask,
      +			if (!pseudotransparency) {
      +				MODBIT(xw.attrs.event_mask, 0, PropertyChangeMask);
      +				XChangeWindowAttributes(xw.dpy, xw.win, CWEventMask,
       					&xw.attrs);
      +			}
       		}
       
       		if (type == incratom) {
      @@ -851,9 +867,9 @@ xsetcolorname(int x, const char *name)
       void
       xclear(int x1, int y1, int x2, int y2)
       {
      -	XftDrawRect(xw.draw,
      -			&dc.col[IS_SET(MODE_REVERSE)? defaultfg : defaultbg],
      -			x1, y1, x2-x1, y2-y1);
      +	if (pseudotransparency)
      +		XSetTSOrigin(xw.dpy, xw.bggc, -win.x, -win.y);
      +	XFillRectangle(xw.dpy, xw.buf, xw.bggc, x1, y1, x2 - x1, y2 - y1);
       }
       
       void
      @@ -1196,24 +1212,9 @@ xinit(int cols, int rows)
       	                                       ximinstantiate, NULL);
       	}
       
      -	/* white cursor, black outline */
      -	cursor = XCreateFontCursor(xw.dpy, mouseshape);
      +	cursor = XcursorLibraryLoadCursor(xw.dpy, mouseshape);
       	XDefineCursor(xw.dpy, xw.win, cursor);
       
      -	if (XParseColor(xw.dpy, xw.cmap, colorname[mousefg], &xmousefg) == 0) {
      -		xmousefg.red   = 0xffff;
      -		xmousefg.green = 0xffff;
      -		xmousefg.blue  = 0xffff;
      -	}
      -
      -	if (XParseColor(xw.dpy, xw.cmap, colorname[mousebg], &xmousebg) == 0) {
      -		xmousebg.red   = 0x0000;
      -		xmousebg.green = 0x0000;
      -		xmousebg.blue  = 0x0000;
      -	}
      -
      -	XRecolorCursor(xw.dpy, cursor, &xmousefg, &xmousebg);
      -
       	xw.xembed = XInternAtom(xw.dpy, "_XEMBED", False);
       	xw.wmdeletewin = XInternAtom(xw.dpy, "WM_DELETE_WINDOW", False);
       	xw.netwmname = XInternAtom(xw.dpy, "_NET_WM_NAME", False);
      @@ -1239,6 +1240,99 @@ xinit(int cols, int rows)
       		xsel.xtarget = XA_STRING;
       }
       
      +void
      +updatexy()
      +{
      +	Window child;
      +	XTranslateCoordinates(xw.dpy, xw.win, DefaultRootWindow(xw.dpy), 0, 0, &win.x, &win.y, &child);
      +}
      +
      +/*
      + * load farbfeld file to XImage
      + */
      +XImage*
      +loadff(const char *filename)
      +{
      +	uint32_t i, hdr[4], w, h, size;
      +	uint64_t *data;
      +	FILE *f = fopen(filename, "rb");
      +
      +	if (f == NULL) {
      +		fprintf(stderr, "Can not open background image file\n");
      +		return NULL;
      +	}
      +
      +	if (fread(hdr, sizeof(*hdr), LEN(hdr), f) != LEN(hdr))
      +		if (ferror(f)) {
      +			fprintf(stderr, "fread:");
      +			return NULL;
      +		}
      +		else {
      +			fprintf(stderr, "fread: Unexpected end of file\n");
      +			return NULL;
      +		}
      +
      +	if (memcmp("farbfeld", hdr, sizeof("farbfeld") - 1)) {
      +		fprintf(stderr, "Invalid magic value\n");
      +		return NULL;
      +	}
      +
      +	w = ntohl(hdr[2]);
      +	h = ntohl(hdr[3]);
      +	size = w * h;
      +	data = malloc(size * sizeof(uint64_t));
      +
      +	if (fread(data, sizeof(uint64_t), size, f) != size)
      +		if (ferror(f)) {
      +			fprintf(stderr, "fread:");
      +			return NULL;
      +		}
      +		else {
      +			fprintf(stderr, "fread: Unexpected end of file\n");
      +			return NULL;
      +		}
      +
      +	fclose(f);
      +
      +	for (i = 0; i < size; i++)
      +		data[i] = (data[i] & 0x00000000000000FF) << 16 |
      +			  (data[i] & 0x0000000000FF0000) >> 8  |
      +			  (data[i] & 0x000000FF00000000) >> 32;
      +
      +	XImage *xi = XCreateImage(xw.dpy, DefaultVisual(xw.dpy, xw.scr),
      +	                            DefaultDepth(xw.dpy, xw.scr), ZPixmap, 0,
      +	                            (char *)data, w, h, 32, w * 8);
      +	xi->bits_per_pixel = 64;
      +	return xi;
      +}
      +
      +/*
      + * initialize background image
      + */
      +void
      +bginit()
      +{
      +	XGCValues gcvalues;
      +	Drawable bgimg;
      +	XImage *bgxi = loadff(bgfile);
      +
      +	memset(&gcvalues, 0, sizeof(gcvalues));
      +	xw.bggc = XCreateGC(xw.dpy, xw.win, 0, &gcvalues);
      +	if (!bgxi) return;
      +	bgimg = XCreatePixmap(xw.dpy, xw.win, bgxi->width, bgxi->height,
      +	                      DefaultDepth(xw.dpy, xw.scr));
      +	XPutImage(xw.dpy, bgimg, dc.gc, bgxi, 0, 0, 0, 0, bgxi->width,
      +	          bgxi->height);
      +	XDestroyImage(bgxi);
      +	XSetTile(xw.dpy, xw.bggc, bgimg);
      +	XSetFillStyle(xw.dpy, xw.bggc, FillTiled);
      +	if (pseudotransparency) {
      +		updatexy();
      +		MODBIT(xw.attrs.event_mask, 1, PropertyChangeMask);
      +		XChangeWindowAttributes(xw.dpy, xw.win, CWEventMask, &xw.attrs);
      +	}
      +}
      +
       int
       xmakeglyphfontspecs(XftGlyphFontSpec *specs, const Glyph *glyphs, int len, int x, int y)
       {
      @@ -1372,7 +1466,7 @@ xmakeglyphfontspecs(XftGlyphFontSpec *specs, const Glyph *glyphs, int len, int x
       }
       
       void
      -xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, int y)
      +xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, int y, int dmode)
       {
       	int charlen = len * ((base.mode & ATTR_WIDE) ? 2 : 1);
       	int winx = borderpx + x * win.cw, winy = borderpx + y * win.ch,
      @@ -1412,10 +1506,6 @@ xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, i
       		bg = &dc.col[base.bg];
       	}
       
      -	/* Change basic system colors [0-7] to bright system colors [8-15] */
      -	if ((base.mode & ATTR_BOLD_FAINT) == ATTR_BOLD && BETWEEN(base.fg, 0, 7))
      -		fg = &dc.col[base.fg + 8];
      -
       	if (IS_SET(MODE_REVERSE)) {
       		if (fg == &dc.col[defaultfg]) {
       			fg = &dc.col[defaultbg];
      @@ -1463,47 +1553,43 @@ xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, i
       	if (base.mode & ATTR_INVISIBLE)
       		fg = bg;
       
      -	/* Intelligent cleaning up of the borders. */
      -	if (x == 0) {
      -		xclear(0, (y == 0)? 0 : winy, borderpx,
      -			winy + win.ch +
      -			((winy + win.ch >= borderpx + win.th)? win.h : 0));
      -	}
      -	if (winx + width >= borderpx + win.tw) {
      -		xclear(winx + width, (y == 0)? 0 : winy, win.w,
      -			((winy + win.ch >= borderpx + win.th)? win.h : (winy + win.ch)));
      -	}
      -	if (y == 0)
      -		xclear(winx, 0, winx + width, borderpx);
      -	if (winy + win.ch >= borderpx + win.th)
      -		xclear(winx, winy + win.ch, winx + width, win.h);
      -
      -	/* Clean up the region we want to draw to. */
      -	XftDrawRect(xw.draw, bg, winx, winy, width, win.ch);
      -
      -	/* Set the clip region because Xft is sometimes dirty. */
      -	r.x = 0;
      -	r.y = 0;
      -	r.height = win.ch;
      -	r.width = width;
      -	XftDrawSetClipRectangles(xw.draw, winx, winy, &r, 1);
      -
      -	/* Render the glyphs. */
      -	XftDrawGlyphFontSpec(xw.draw, fg, specs, len);
      -
      -	/* Render underline and strikethrough. */
      -	if (base.mode & ATTR_UNDERLINE) {
      -		XftDrawRect(xw.draw, fg, winx, winy + dc.font.ascent * chscale + 1,
      -				width, 1);
      -	}
      -
      -	if (base.mode & ATTR_STRUCK) {
      -		XftDrawRect(xw.draw, fg, winx, winy + 2 * dc.font.ascent * chscale / 3,
      -				width, 1);
      -	}
      -
      -	/* Reset clip to none. */
      -	XftDrawSetClip(xw.draw, 0);
      +	if (dmode & DRAW_BG) {
      +        /* Intelligent cleaning up of the borders. */
      +        if (x == 0) {
      +            xclear(0, (y == 0)? 0 : winy, borderpx,
      +                   winy + win.ch +
      +                   ((winy + win.ch >= borderpx + win.th)? win.h : 0));
      +        }
      +        if (winx + width >= borderpx + win.tw) {
      +            xclear(winx + width, (y == 0)? 0 : winy, win.w,
      +                   ((winy + win.ch >= borderpx + win.th)? win.h : (winy + win.ch)));
      +        }
      +        if (y == 0)
      +            xclear(winx, 0, winx + width, borderpx);
      +        if (winy + win.ch >= borderpx + win.th)
      +            xclear(winx, winy + win.ch, winx + width, win.h);
      +        /* Fill the background */
      +		if (bg == &dc.col[defaultbg])
      +			xclear(winx, winy, winx + width, winy + win.ch);
      +		else
      +			XftDrawRect(xw.draw, bg, winx, winy, width, win.ch);
      +    }
      +
      +    if (dmode & DRAW_FG) {
      +        /* Render the glyphs. */
      +        XftDrawGlyphFontSpec(xw.draw, fg, specs, len);
      +
      +        /* Render underline and strikethrough. */
      +        if (base.mode & ATTR_UNDERLINE) {
      +            XftDrawRect(xw.draw, fg, winx, winy + dc.font.ascent + 1,
      +                        width, 1);
      +        }
      +
      +        if (base.mode & ATTR_STRUCK) {
      +            XftDrawRect(xw.draw, fg, winx, winy + 2 * dc.font.ascent / 3,
      +                        width, 1);
      +        }
      +    }
       }
       
       void
      @@ -1513,7 +1599,7 @@ xdrawglyph(Glyph g, int x, int y)
       	XftGlyphFontSpec spec;
       
       	numspecs = xmakeglyphfontspecs(&spec, &g, 1, x, y);
      -	xdrawglyphfontspecs(&spec, g, numspecs, x, y);
      +	xdrawglyphfontspecs(&spec, g, numspecs, x, y, DRAW_BG | DRAW_FG);
       }
       
       void
      @@ -1648,32 +1734,39 @@ xstartdraw(void)
       void
       xdrawline(Line line, int x1, int y1, int x2)
       {
      -	int i, x, ox, numspecs;
      +	int i, x, ox, numspecs, numspecs_cached;
       	Glyph base, new;
      -	XftGlyphFontSpec *specs = xw.specbuf;
      -
      -	numspecs = xmakeglyphfontspecs(specs, &line[x1], x2 - x1, x1, y1);
      -	i = ox = 0;
      -	for (x = x1; x < x2 && i < numspecs; x++) {
      -		new = line[x];
      -		if (new.mode == ATTR_WDUMMY)
      -			continue;
      -		if (selected(x, y1))
      -			new.mode ^= ATTR_REVERSE;
      -		if (i > 0 && ATTRCMP(base, new)) {
      -			xdrawglyphfontspecs(specs, base, i, ox, y1);
      -			specs += i;
      -			numspecs -= i;
      -			i = 0;
      -		}
      -		if (i == 0) {
      -			ox = x;
      -			base = new;
      +	XftGlyphFontSpec *specs;
      +
      +	numspecs_cached = xmakeglyphfontspecs(xw.specbuf, &line[x1], x2 - x1, x1, y1);
      +
      +	/* Draw line in 2 passes: background and foreground. This way wide glyphs
      +       won't get truncated (#223) */
      +	for (int dmode = DRAW_BG; dmode <= DRAW_FG; dmode <<= 1) {
      +		specs = xw.specbuf;
      +		numspecs = numspecs_cached;
      +		i = ox = 0;
      +		for (x = x1; x < x2 && i < numspecs; x++) {
      +			new = line[x];
      +			if (new.mode == ATTR_WDUMMY)
      +				continue;
      +			if (selected(x, y1))
      +				new.mode ^= ATTR_REVERSE;
      +			if (i > 0 && ATTRCMP(base, new)) {
      +				xdrawglyphfontspecs(specs, base, i, ox, y1, dmode);
      +				specs += i;
      +				numspecs -= i;
      +				i = 0;
      +			}
      +			if (i == 0) {
      +				ox = x;
      +				base = new;
      +			}
      +			i++;
       		}
      -		i++;
      +		if (i > 0)
      +			xdrawglyphfontspecs(specs, base, i, ox, y1, dmode);
       	}
      -	if (i > 0)
      -		xdrawglyphfontspecs(specs, base, i, ox, y1);
       }
       
       void
      @@ -1905,8 +1998,17 @@ cmessage(XEvent *e)
       void
       resize(XEvent *e)
       {
      -	if (e->xconfigure.width == win.w && e->xconfigure.height == win.h)
      -		return;
      +	if (pseudotransparency) {
      +		if (e->xconfigure.width == win.w &&
      +		    e->xconfigure.height == win.h &&
      +		    e->xconfigure.x == win.x && e->xconfigure.y == win.y)
      +			return;
      +		updatexy();
      +	} else {
      +		if (e->xconfigure.width == win.w &&
      +		    e->xconfigure.height == win.h)
      +			return;
      +	}
       
       	cresize(e->xconfigure.width, e->xconfigure.height);
       }
      @@ -2091,6 +2193,7 @@ run:
       	rows = MAX(rows, 1);
       	tnew(cols, rows);
       	xinit(cols, rows);
      +	bginit();
       	xsetenv();
       	selinit();
       	run();
      -- 
      2.42.0

    '';
}
