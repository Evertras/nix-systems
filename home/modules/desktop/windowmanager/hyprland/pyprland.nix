{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.desktop.windowmanager.hyprland.pyprland;
in {
  options.evertras.home.desktop.windowmanager.hyprland.pyprland = {
    enable = mkEnableOption "Enable Pyprland plugins for Hyprland";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ pyprland ];

      file = {
        ".config/hypr/pyprland.toml" = {
          text = ''
            [pyprland]
            plugins = [ "scratchpads" ]

            [scratchpads.pavucontrol]
            animation = "fromTop"
            command = "pavucontrol"
            class = "pavucontrol"
            size = "50% 50%"
          '';
        };
      };
    };
  };
}
