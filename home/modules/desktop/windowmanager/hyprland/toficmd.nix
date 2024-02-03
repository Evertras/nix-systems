{ type, lib, theme }:
with lib;
let
  mkColor = strings.removePrefix "#";
  tofiThemes = {
    dmenu = {
      anchor = "top";
      ascii-input = "false";
      background-color = mkColor theme.colors.background;
      border-color = mkColor theme.colors.contrast;
      border-width = 0;
      font-size = 12;
      fuzzy-match = "true";
      height = 30;
      outline-width = 0;
      padding-bottom = 0;
      padding-left = 10;
      padding-right = 0;
      padding-top = 5;
      prompt-text = "run> ";
      result-spacing = 15;
      width = "100%";
    };
  };
  tofiFlags = [ "--horizontal=true" ]
    ++ (attrsets.mapAttrsToList (key: value: "'--${key}=${toString value}'")
      tofiThemes.${type});
in "tofi-run " + (strings.concatStringsSep " " tofiFlags)
