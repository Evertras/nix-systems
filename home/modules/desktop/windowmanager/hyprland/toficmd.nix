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
      horizontal = "true";
      outline-width = 0;
      padding-bottom = 0;
      padding-left = 10;
      padding-right = 0;
      padding-top = 5;
      prompt-text = "run> ";
      result-spacing = 15;
      width = "100%";
    };

    fullscreen = {
      width = "100%";
      height = "100%";
      border-width = 0;
      outline-width = 0;
      padding-left = "35%";
      padding-top = "35%";
      result-spacing = 25;
      prompt-text = "run > ";
      num-results = 5;
      text-color = mkColor theme.colors.text;
      prompt-color = mkColor theme.colors.primary;
      background-color = mkColor theme.colors.background;
      selection-color = mkColor theme.colors.contrast;
    };
  };
  tofiFlags =
    (attrsets.mapAttrsToList (key: value: "'--${key}=${toString value}'")
      tofiThemes.${type});
in "tofi-run " + (strings.concatStringsSep " " tofiFlags)
