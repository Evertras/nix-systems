{ config, everlib, lib, pkgs, ... }:
with lib;
with everlib;
let
  cfg = config.evertras.home.desktop.launchers.tofi;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.launchers.tofi = {
    enable = mkEnableOption "Enable Tofi";
  };

  config = mkIf cfg.enable {
    evertras.home.shell.funcs = {
      launch-app-tofi-fullscreen.body = let
        command = import ./cmd.nix {
          inherit theme lib;
          type = "fullscreen";
        };
      in ''
        eval "$(${command})"
      '';

      launch-app-tofi-dmenu.body = let
        command = import ./cmd.nix {
          inherit theme lib;
          type = "dmenu";
        };
      in ''
        eval "$(${command})"
      '';
    };

    home.packages = with pkgs; [ tofi ];
  };
}
