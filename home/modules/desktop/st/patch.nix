{ }: {
  mkPatch = { fontName, fontSize, colors }:

    builtins.toFile "ever-st.diff" ''

      From 3b235a7f1abefec7f14379ed63a204f438a8cf81 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Fri, 12 Jan 2024 09:04:28 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h |  18 +++----
       st.h         |   6 +++
       x.c          | 138 +++++++++++++++++++++++++--------------------------
       3 files changed, 82 insertions(+), 80 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 91ab8ca..9549b0e 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -5,7 +5,7 @@
        *
        * font: see http://freedesktop.org/software/fontconfig/fontconfig-user.html
        */
      -static char *font = "Liberation Mono:pixelsize=12:antialias=true:autohint=true";
      +static char *font = "${fontName}:pixelsize=${
        toString fontSize
      }:antialias=true:autohint=true";
       static int borderpx = 2;
       
       /*
      @@ -97,12 +97,12 @@ unsigned int tabspaces = 8;
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
      @@ -120,8 +120,8 @@ static const char *colorname[] = {
       	/* more colors can be added after 255 to use with DefaultXX */
       	"#cccccc",
       	"#555555",
      -	"gray90", /* default foreground colour */
      -	"black", /* default background colour */
      +	"${colors.foreground}", /* default foreground colour */
      +	"${colors.background}", /* default background colour */
       };
       
       
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
      index b36fb8c..aa42ab0 100644
      --- a/x.c
      +++ b/x.c
      @@ -142,7 +142,7 @@ typedef struct {
       
       static inline ushort sixd_to_16bit(int);
       static int xmakeglyphfontspecs(XftGlyphFontSpec *, const Glyph *, int, int, int);
      -static void xdrawglyphfontspecs(const XftGlyphFontSpec *, Glyph, int, int, int);
      +static void xdrawglyphfontspecs(const XftGlyphFontSpec *, Glyph, int, int, int, int);
       static void xdrawglyph(Glyph, int, int);
       static void xclear(int, int, int, int);
       static int xgeommasktogravity(int);
      @@ -1372,7 +1372,7 @@ xmakeglyphfontspecs(XftGlyphFontSpec *specs, const Glyph *glyphs, int len, int x
       }
       
       void
      -xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, int y)
      +xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, int y, int dmode)
       {
       	int charlen = len * ((base.mode & ATTR_WIDE) ? 2 : 1);
       	int winx = borderpx + x * win.cw, winy = borderpx + y * win.ch,
      @@ -1412,10 +1412,6 @@ xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, i
       		bg = &dc.col[base.bg];
       	}
       
      -	/* Change basic system colors [0-7] to bright system colors [8-15] */
      -	if ((base.mode & ATTR_BOLD_FAINT) == ATTR_BOLD && BETWEEN(base.fg, 0, 7))
      -		fg = &dc.col[base.fg + 8];
      -
       	if (IS_SET(MODE_REVERSE)) {
       		if (fg == &dc.col[defaultfg]) {
       			fg = &dc.col[defaultbg];
      @@ -1463,47 +1459,40 @@ xdrawglyphfontspecs(const XftGlyphFontSpec *specs, Glyph base, int len, int x, i
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
      +        XftDrawRect(xw.draw, bg, winx, winy, width, win.ch);
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
      @@ -1513,7 +1502,7 @@ xdrawglyph(Glyph g, int x, int y)
       	XftGlyphFontSpec spec;
       
       	numspecs = xmakeglyphfontspecs(&spec, &g, 1, x, y);
      -	xdrawglyphfontspecs(&spec, g, numspecs, x, y);
      +	xdrawglyphfontspecs(&spec, g, numspecs, x, y, DRAW_BG | DRAW_FG);
       }
       
       void
      @@ -1648,32 +1637,39 @@ xstartdraw(void)
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
      -- 
      2.42.0

    '';
}