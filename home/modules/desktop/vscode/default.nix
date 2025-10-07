{ config, everlib, lib, ... }:
with everlib;
with lib;
let
  cfg = config.evertras.home.desktop.vscode;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.vscode = { enable = mkEnableOption "vscode"; };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;

      profiles.default = { enableUpdateCheck = false; };
    };
  };
}
