{ colors }: {
  # Note to future self: be VERY careful about preserving
  # whitespace/tabs inside the actual strings...

  # Colors can be configured by command line options, but let's
  # overengineer and learn how to do dynamic patches!
  mkColorPatch = { colors }:
    builtins.toFile "dmenu-color-patch.diff" ''
      From 7156b7d81c70e9381d19e62cfbc29c9295671516 Mon Sep 17 00:00:00 2001
      From: Brandon Fulljames <bfullj@gmail.com>
      Date: Thu, 11 Jan 2024 21:59:18 +0900
      Subject: [PATCH] Changes

      ---
       config.def.h | 6 +++---
       1 file changed, 3 insertions(+), 3 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 1edb647..67bb990 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -9,9 +9,9 @@ static const char *fonts[] = {
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
