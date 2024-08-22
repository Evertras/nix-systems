{ config, lib, pkgs, ... }:
with lib;
let
  patch = (import ./patch.nix) { };
  cfg = config.evertras.home.desktop.windowmanager.dwm;
  usingNixOS = config.evertras.home.core.usingNixOS;
  theme = config.evertras.themes.selected;

  # Generate autostart commands
  makeCmd = cmd: ''"sh", "-c", "${strings.escape [ ''"'' ] cmd}", NULL,'';
  converted = map makeCmd cfg.autostartCmds;
  autostartCmds = strings.concatStrings converted;

  basePatch = patch.mkBasePatch {
    autostartCmds = autostartCmds;
    borderpx = cfg.borderpx;
    browser = cfg.browser;
    colorBackground = theme.colors.background;
    colorPrimary = theme.colors.primary;
    colorText = theme.colors.text;
    fontName = theme.fonts.main.name;
    fontSize = cfg.fontSize;
    gappx = cfg.gappx;
    lock = cfg.lock;
    modKey = cfg.modKey;
    swapFocusKey = cfg.swapFocusKey;
    terminal = cfg.terminal;
  };
  patchList = [ basePatch ];
  customDwm = pkgs.dwm.overrideAttrs (self: super: {
    src = ./src;
    patches =
      if super.patches == null then patchList else super.patches ++ patchList;
    buildInputs = super.buildInputs ++ [ pkgs.xorg.libXcursor ];
  });
in {
  options.evertras.home.desktop.windowmanager.dwm = {
    enable = mkEnableOption "dwm";

    autostartCmds = mkOption {
      type = with types; listOf str;
      default = [ ];
    };

    borderpx = mkOption {
      description = "The size of borders around windows";
      type = types.int;
      default = 1;
    };

    browser = mkOption { type = types.str; };

    fontSize = mkOption {
      description = "The size of the font";
      type = types.int;
      default = 16;
    };

    gappx = mkOption {
      description = "The size of gaps between windows";
      type = types.int;
      default = 20;
    };

    lock = mkOption {
      type = types.str;
      default = "slock";
    };

    modKey = mkOption {
      type = types.str;
      default = "Mod4Mask";
      description = ''
        The modifier key to use for dwm.

        Mod4Mask is the windows/cmd super key.
        Mod1Mask is the alt key.
      '';
    };

    swapFocusKey = mkOption {
      type = types.str;
      default = "XK_Return";
      description = ''
        The key to use to make the current window
        the main window, or swap the main window
        with the stack.
      '';
    };

    terminal = mkOption {
      type = types.str;
      default = "kitty";
    };
  };

  config = let systemfile-path = ".evertras/systemfiles/dwm.desktop";
  in mkIf cfg.enable {
    home.packages = [ customDwm ];

    home.file = {
      "${systemfile-path}" = {
        text = ''
          [Desktop Entry]
          Name=dwm-nix-hm
          Comment=dwm via home-manager
          Exec=${customDwm}/bin/dwm
          Type=XSession
          DesktopNames=dwm
        '';
      };
    };

    # This unfortunately seems necessary if we're not using NixOS...
    evertras.home.shell.funcs = if usingNixOS then
      { }
    else {
      "install-dwm-without-nixos".body = ''
        linkfile=/usr/share/xsessions/dwm-nix-hm.desktop
        echo "Upserting linkfile $linkfile"
        sudo rm -f "$linkfile"
        sudo ln -s ~/${systemfile-path} "$linkfile"
      '';
    };
  };
}
