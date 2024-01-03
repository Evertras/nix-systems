{ config, lib, pkgs, ... }:
{
  # Desktop environment
  # https://nixos.wiki/wiki/I3
  services.xserver = {
    enable = true;
    layout = "jp";

    displayManager = {
      defaultSession = "none+i3";

      autoLogin.user = "evertras";

      # Sleep seems to be required for avoiding some init race
      # not great but works for now.  Note that if the resolution
      # doesn't change, check video memory in VM settings.
      sessionCommands = ''
        xrandr --output Virtual1 --mode 2560x1440
        picom -f &
        (sleep 1s && setxkbmap -layout jp && styli.sh -s mountain) &
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
}
