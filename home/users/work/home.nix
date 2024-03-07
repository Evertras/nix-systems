{ lib, nerdfonts, pkgs, ... }:

let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Mauve"; };

  gpgKey = "9C6A5922D90A8465";

  displayLeft = {
    name = "DP-1-3";
    resolution = "3840x2160";
  };

  displayCenter = {
    name = "DP-2";
    resolution = "3840x2160";
  };

  displayRight = {
    name = "HDMI-0";
    resolution = "1920x1080";
  };

  # Use the wrapped version to get around OpenGL issues
  terminal = "alacritty-gl";

  terminalFont = "FantasqueSansM";

  # Custom lock script outside of home-manager
  customLockCmd = "/home/brandon-fulljames/.evertras/funcs/lock";
in {
  imports = [ ../../modules ../../../shared/themes/select.nix ];

  evertras.themes.selected = (theme // {
    fonts = (theme.fonts // { terminal = nerdfonts.makeMono terminalFont; });
  });

  evertras.home = {
    core = {
      username = "brandon-fulljames";
      usingNixOS = false;
    };

    audio = {
      enable = true;
      enableDesktop = true;
      headphonesMacAddress = "EC:66:D1:B8:95:88";
    };

    shell = {
      core = { inherit gpgKey; };

      coding.haskell.enable = true;

      git.userEmail = "brandon.fulljames@woven-planet.global";

      funcs = {
        aws-login.body = "aws sso login";
        kitty-gl.body = "nixGL kitty -1";
        alacritty-gl.body = "nixGL alacritty";
      };
    };

    desktop = {
      enable = true;

      browsers = {
        enableLibrewolf = false;
        enableChromium = true;

        # Already have firefox running/configured/bookmarked, maybe tweak later
        default = "firefox";
      };

      kbLayout = "us";

      ime.enable = true;

      display.sleep.enable = true;

      notifications = {
        enable = true;
        origin = "top-right";
      };

      terminals = {
        alacritty = {
          enable = true;

          fontSize = 14;
        };

        kitty.enable = true;

        st = {
          enable = true;

          font = nerdfonts.makeMono "ProFont IIx";
          fontSize = 13;

          bgBlurPixels = 0;
          bgOpacityPercent100 = 80;

          desktopResolution = "3840x2160";
        };
      };

      windowmanager = {
        # Doesn't work yet, seems to be challenging in old ubuntu
        # especially with nvidia
        hyprland = {
          enable = true;
          kbLayout = "jp";

          displays =
            let scaleAdjust = display: scale: (display // { inherit scale; });
            in [ displayLeft displayCenter displayRight ];
        };

        dwm = {
          enable = true;

          autostartCmds = [
            "autorandr -l main && sleep 1 && (/home/brandon-fulljames/.fehbg || feh --bg-fill /home/brandon-fulljames/Pictures/desktops/forest-butterflies.jpeg)"
            "setxkbmap -layout us"
            "sleep 5s; systemctl --user restart dunst"
            # Pre-installed picom
            "sleep 5s; /home/brandon-fulljames/bin/picom"
          ];

          borderpx = 2;

          swapFocusKey = "XK_Tab";

          lock = customLockCmd;

          inherit terminal;
        };

        i3 = {
          # Enable anyway to switch back and forth
          enable = true;

          monitorNetworkInterface = "eno1";

          # TODO: Fix 'Mod4'
          keybindOverrides = {
            # For some reason space is lower case, so need this to override
            "Mod4+space" = "exec ${terminal}";
            # Custom local lock
            "Mod4+Escape" = "exec ${customLockCmd}";
          };

          startupPreCommands = [ "autorandr -l main" ];

          startupPostCommands = [ "/home/brandon-fulljames/bin/picom &" ];

          # Don't want status in right monitor since it's vertical
          bars = [
            {
              id = "main";
              outputs = [ displayLeft.name displayCenter.name ];
            }
            {
              id = "right";
              outputs = [ displayRight.name ];
              showStatus = false;
            }
          ];
        };
      };
    };
  };

  # We have picom already installed and working via Ubuntu,
  # so use it to avoid OpenGL headaches
  services.picom.enable = false;

  programs.autorandr = {
    enable = true;

    profiles = {
      main = {
        fingerprint = {
          DP-1-3 =
            "00ffffffffffff0010acbc414c464744141e0104b53c22783eee95a3544c99260f5054a54b00e1c0d100d1c0b300a94081808100714f4dd000a0f0703e803020350055502100001a000000ff00444c56435831330a2020202020000000fd00184b1e8c36010a202020202020000000fc0044454c4c205532373230514d0a0148020319f14c101f2005140413121103020123097f0783010000a36600a0f0703e803020350055502100001a565e00a0a0a029503020350055502100001a114400a0800025503020360055502100001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d9";
          DP-2 =
            "00ffffffffffff00410c0b096a010000171d0104b54628783a5905af4f42af270e5054bd4b00d1c081808140950f9500b30081c001014dd000a0f0703e8030203500ba8e2100001aa36600a0f0701f8030203500ba8e2100001a000000fc0050484c203332385036560a2020000000fd0017501ea03c010a20202020202001fc020326f14b101f04130312021101051423090707830100006d030c00100019782000600102038c0ad08a20e02d10103e9600ba8e21000018011d007251d01e206e285500ba8e2100001e4d6c80a070703e8030203a00ba8e2100001a7d3900a080381f4030203a00ba8e2100001a0000000000000000000000000000000000bf";
          HDMI-0 =
            "00ffffffffffff00410c2909240400000a1d010380351e782aa631a855519d250f5054bfef00d1c0b30095008180814081c001010101023a801871382d40582c45000f282100001e2a4480a070382740302035000f282100001a000000fc0050484c203234314238510a2020000000fd00304c1e5512000a2020202020200165020327f14b101f051404130312021101230907078301000065030c001000681a00000101304c008c0ad08a20e02d10103e96000f2821000018011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f28210000188c0ad090204031200c4055000f282100001800000000000000000000000000000000c4";
        };
        config = {
          # DPI calc: sqrt(width^2 + height^2) / diagInches
          # Note that DPI separate per monitor may not actually work with XOrg,
          # but leaving it here for reference anyway as it doesn't hurt.
          ${displayLeft.name} = {
            crtc = 4;
            enable = true;
            mode = displayLeft.resolution;
            position = "0x0";
            rate = "60.0";
          };

          ${displayCenter.name} = {
            enable = true;
            mode = displayCenter.resolution;
            position = "3840x0";
            rate = "60.0";
          };

          ${displayRight.name} = {
            crtc = 0;
            enable = true;
            mode = displayRight.resolution;
            position = "7680x0";
            rate = "60.0";
            rotate = "left";
          };
        };
      };
    };
  };

  home = {
    # Other local things
    packages = with pkgs; [
      # Even without sound, allows remote control
      spotify-tui

      vagrant
    ];

    file = { ".asdfrc".text = "legacy_version_file = yes"; };

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
