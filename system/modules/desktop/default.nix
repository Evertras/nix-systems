{ config, everlib, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.desktop;
in {
  imports = (everlib.allSubdirs ./.) ++ [ ../../../shared/themes/select.nix ];

  options.evertras.desktop = { enable = mkEnableOption "desktop"; };

  config = mkIf cfg.enable {
    # Needed for GTK tweaks
    # https://github.com/nix-community/home-manager/issues/3113
    programs.dconf.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
    };

    environment.systemPackages = with pkgs;
      [
        # Need to install it here. Just install it, let's face it, I'm using firefox and stop
        # trying to finagle it otherwise...
        #
        # https://discourse.nixos.org/t/screen-sharing-with-wayland-gnome/12449/8
        firefox
      ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      # https://wiki.nixos.org/wiki/Firefox/en#Screen_Sharing_under_Wayland
      XDG_CURRENT_DESKTOP = "sway";
    };
  };
}
