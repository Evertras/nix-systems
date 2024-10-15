{ type, lib, theme }:
with lib;
let
  mkColor = strings.removePrefix "#";
  sharedSettings = {
    ascii-input = "false";
    fuzzy-match = "true";
    hide-cursor = "true";
  };

  tofiThemes = {
    dmenu = {
      anchor = "top";
      background-color = mkColor theme.colors.background;
      border-color = mkColor theme.colors.contrast;
      border-width = 0;
      font-size = 12;
      height = 30;
      horizontal = "true";
      outline-width = 0;
      padding-bottom = 0;
      padding-left = 10;
      padding-right = 0;
      padding-top = 5;
      prompt-text = "run❯";
      result-spacing = 15;
      width = "100%";
    };

    fullscreen = {
      background-color = mkColor theme.colors.background;
      border-width = 0;
      height = "100%";
      num-results = 5;
      outline-width = 0;
      padding-left = "35%";
      padding-top = "35%";
      prompt-color = mkColor theme.colors.primary;
      prompt-text = "run ❯ ";
      result-spacing = 25;
      selection-color = mkColor theme.colors.contrast;
      text-color = mkColor theme.colors.text;
      width = "100%";
    };
  };
  tofiFlags =
    (attrsets.mapAttrsToList (key: value: "--${key}='${toString value}'")
      (tofiThemes.${type} // sharedSettings));
in "tofi-run " + (strings.concatStringsSep " " tofiFlags)
