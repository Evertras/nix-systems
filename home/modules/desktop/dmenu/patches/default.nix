{ }: {
  mkColorPatch = { colorSelection }:
    builtins.toFile "dmenu-color-patch.diff" ''
      ---
       config.def.h | 4 ++--
       1 file changed, 2 insertions(+), 2 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 1edb647..e688388 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -9,8 +9,8 @@ static const char *fonts[] = {
       static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
       static const char *colors[SchemeLast][2] = {
       	/*     fg         bg       */
      -	[SchemeNorm] = { "#bbbbbb", "#222222" },
      -	[SchemeSel] = { "#eeeeee", "#005577" },
      +	[SchemeNorm] = { "#f8f8f2", "#282a36" },
      +	[SchemeSel] = { "#f8f8f2", "${colorSelection}" },
       	[SchemeOut] = { "#000000", "#00ffff" },
       };
       /* -l option; if nonzero, dmenu uses vertical list with given number of lines */
      -- 
      2.34.1

    '';
}
