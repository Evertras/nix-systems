{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.desktop.xserver;
  theme = config.evertras.themes.selected;
in {
  options.evertras.desktop.xserver = {
    enable = mkEnableOption "Desktop xserver";

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
        sessionCommands = ''
          ${cfg.extraSessionCommands}
        '';

        session = [{
          manage = "desktop";
          name = "dwm";
          start = ''
            dwm
            waitPID=$!
          '';
        }];

        # Explicitly enable lightDM in case we log back out,
        # just to remind ourselves which thing we're using...
        # in the future, explore removing this and using xstart
        lightdm = {
          enable = true;

          greeters.gtk.cursorTheme = {
            name = theme.cursorTheme.name;
            package = theme.cursorTheme.package;
          };
        };
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
