{ }: {
  # Note to future self: be VERY careful about preserving
  # whitespace/tabs inside the actual strings...
  mkBasePatch = { terminal ? "st" }:
    builtins.toFile "dwm-base-patch.diff" ''
      ---
       config.def.h | 4 ++--
       1 file changed, 2 insertions(+), 2 deletions(-)

      diff --git a/config.def.h b/config.def.h
      index 9efa774..0a09533 100644
      --- a/config.def.h
      +++ b/config.def.h
      @@ -57,8 +57,8 @@ static const Layout layouts[] = {
       
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
