{ config, everlib, lib, ... }:
with lib;
let cfg = config.evertras.desktop;
in {
  imports = (everlib.allSubdirs ./.) ++ [ ../../../shared/themes/select.nix ];

  options.evertras.desktop = { enable = mkEnableOption "desktop"; };

  config = mkIf cfg.enable {
    # Needed for GTK tweaks
    # https://github.com/nix-community/home-manager/issues/3113
    programs.dconf.enable = true;
  };
}
