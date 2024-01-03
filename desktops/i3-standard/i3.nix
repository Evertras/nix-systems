# Desktop environment
# https://nixos.wiki/wiki/I3
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.evertras.desktop.i3;
in {
  options.evertras.desktop.i3 = {
    enable = mkEnableOption "i3 desktop";

    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      layout = cfg.kbLayout;

      displayManager = {
        defaultSession = "none+i3";

        # Sleep seems to be required for avoiding some init race
        # not great but works for now.  Note that if the resolution
        # doesn't change, check video memory in VM settings.
        sessionCommands = ''
          xrandr --output Virtual1 --mode 2560x1440
          picom -f &
          (sleep 1s && setxkbmap -layout ${cfg.kbLayout} && styli.sh -s mountain) &
        '';

        # Explicitly enable lightDM in case we log back out,
        # just to remind ourselves which thing we're using...
        lightdm = {
          enable = true;
        };
      };

      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu
          i3status
          i3lock
          picom-next
          # TODO: look at i3blocks?
        ];
      };

      # Disable capslock, trying to remap it to ctrl
      # seems to do some weird things
      xkb.options = "caps:none";
    };
  };
}
