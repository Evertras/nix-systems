# Desktop environment
# https://nixos.wiki/wiki/I3
{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.desktop.i3;
in {
  options.evertras.desktop.i3 = {
    enable = mkEnableOption "i3 desktop";

    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };

    extraSessionCommands = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      layout = cfg.kbLayout;

      displayManager = {
        defaultSession = "none+i3";

        sessionCommands = ''
          ${cfg.extraSessionCommands}
        '';

        # Explicitly enable lightDM in case we log back out,
        # just to remind ourselves which thing we're using...
        lightdm = { enable = true; };
      };

      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          i3status
          i3lock
          # TODO: look at i3blocks?
        ];
      };

      # Disable capslock, trying to remap it to ctrl
      # seems to do some weird things
      xkb.options = "caps:none";
    };

    # Needed for GTK tweaks
    # https://github.com/nix-community/home-manager/issues/3113
    programs.dconf = { enable = true; };
  };
}
