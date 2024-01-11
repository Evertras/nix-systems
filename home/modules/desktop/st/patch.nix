{ }: {
  mkPatch = { fontName, fontSize, shell }:
    builtins.toFile "ever-st.diff" ''

      From 4ec6d39291754aeb57d288c2959c13e7292cf790 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Fri, 12 Jan 2024 08:12:13 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h | 4 ++--
       1 file changed, 2 insertions(+), 2 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 91ab8ca..fe0fe08 100644
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
      @@ -16,7 +16,7 @@ static int borderpx = 2;
        * 4: value of shell in /etc/passwd
        * 5: value of shell in config.h
        */
      -static char *shell = "/bin/sh";
      +static char *shell = "${shell}";
       char *utmp = NULL;
       /* scroll program: to enable use a string like "scroll" */
       char *scroll = NULL;
      -- 
      2.42.0

    '';
}
