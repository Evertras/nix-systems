{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.desktop.terminals.alacritty;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.terminals.alacritty = {
    enable = mkEnableOption "alacritty";
  };

  config = mkIf cfg.enable { programs.alacritty = { enable = true; }; };
}
