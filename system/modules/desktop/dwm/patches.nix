{ lib }:
with lib; {
  # Note to future self: be VERY careful about preserving
  # whitespace/tabs inside the actual strings...
  mkBasePatch =
    { terminal, colorPrimary, colorText, colorBackground, fontSize, fontName }:
    builtins.toFile "dwm-base-patch.diff" ''

      From 2f9c50fe88d358177dead2973febe0d81c361325 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Wed, 10 Jan 2024 22:06:58 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h | 24 ++++++++++--------------
       1 file changed, 10 insertions(+), 14 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 9efa774..3478cc0 100644
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
      @@ -40,12 +37,11 @@ static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen win
       static const Layout layouts[] = {
       	/* symbol     arrange function */
       	{ "[]=",      tile },    /* first entry is default */
      -	{ "><>",      NULL },    /* no layout function means floating behavior */
       	{ "[M]",      monocle },
       };
       
       /* key definitions */
      -#define MODKEY Mod1Mask
      +#define MODKEY Mod4Mask
       #define TAGKEYS(KEY,TAG) \
       	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
       	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
      @@ -57,8 +53,8 @@ static const Layout layouts[] = {
       
       /* commands */
       static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
      -static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
      -static const char *termcmd[]  = { "st", NULL };
      +static const char *dmenucmd[] = { "dmenu_run", NULL };
      +static const char *termcmd[]  = { "${terminal}", NULL };
       
       static const Key keys[] = {
       	/* modifier                     key        function        argument */
      -- 
      2.42.0

    '';
}
