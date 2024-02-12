{ lib, ... }:
with lib; {
  # To be applied to individual shell rcs in ../shells/
  options.evertras.home.shell.env = {
    vars = mkOption {
      description = "Environment variables to apply to all shells";
      type = with types; attrsOf str;
      default = {
        # Various recommendations from xdg-ninja to clean
        # up the home directory
        CARGO_HOME = "$XDG_DATA_HOME/cargo";
        CUDA_HOME = "$XDG_DATA_HOME/nv";
        GNUPGHOME = "$XDG_DATA_HOME/gnupg";
        GOPATH = "$XDG_DATA_HOME/go";
        GTK2_RC_FILES = "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";
        XCOMPOSECACHE = "$XDG_CACHE_HOME/X11/xcompose";
      };
    };
  };
}
