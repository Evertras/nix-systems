{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.desktop.core;
in {
  options.evertras.desktop.core = {
    kbLayout = mkOption {
      type = types.str;
      default = "us";
    };

    extraSessionCommands = mkOption {
      type = types.str;
      default = "";
    };
  };

  config = {
    services.xserver = {
      enable = true;
      layout = cfg.kbLayout;

      displayManager = {
        sessionCommands = ''
          ${cfg.extraSessionCommands}
        '';

        # Explicitly enable lightDM in case we log back out,
        # just to remind ourselves which thing we're using...
        # in the future, explore removing this and using xstart
        lightdm = { enable = true; };
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
