{ config, lib, ... }:
with lib;
let cfg = config.evertras.theme;
in {
  # Defines a bunch of constants for use in other
  # modules to create a consistent theme that can be
  # easily switched
  options.evertras.theme = {
    name = mkOption {
      type = types.str;
      default = "mint";
    };
  };

  config.evertras = rec {
    _themes = {
      "mint" = {
        # https://coolors.co/ef6f6c-2e394d-dcf9eb-59c9a5-7a907c
        colors = {
          primary = "#59C9A5";
          highlight = "#A7F1CD";
          background = "#2e394d";
          text = "#DCF9EB";
          urgent = "#EF6F6C";
        };
      };
    };

    theme = _themes.${cfg.theme.name};
  };
}
