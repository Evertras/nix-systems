
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.home.editorconfig;
in {
  options.evertras.home.editorconfig = {
    enable = mkEnableOption "editorconfig";
  };

  config = mkIf cfg.enable {
    editorconfig = {
      enable = true;

      settings = {
        "*" = {
          indent_style = "space";
          indent_size = 2;
          insert_final_newline = true;
          trim_trailing_whitespace = true;
        };

        "*.go" = {
          indent_style = "tab";
        };

        "Makefile" = {
          indent_style = "tab";
        };
      };
    };
  };
}
