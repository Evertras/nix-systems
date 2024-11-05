{ lib, nerdfonts, pkgs, ... }:

let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Mauve"; };

  gpgKey = "92B4C34033DEB5A6";

  # To find:
  # xrandr --query --listactivemonitors
  displayLeft = {
    name = "DP-2";
    resolution = "3840x2160";
  };

  displayCenter = {
    name = "DP-4";
    resolution = "3840x2160";
  };

  displayRight = {
    name = "HDMI-0";
    resolution = "1920x1080";
  };

  # Use the wrapped version to get around OpenGL issues
  terminal = "alacritty-gl";

  fontBerkeley = {
    name = "Berkeley Mono";
    package = pkgs.everfont-berkeley;
  };

  #terminalFont = nerdfonts.makeMono "ProFont IIx";
  fontOverrides = { terminal = fontBerkeley; };

  # 14 is default baseline for most fonts, others may be better adjusted
  terminalFontSize = 14;

  # Custom lock script outside of home-manager
  customLockCmd = "/home/brandon-fulljames/.evertras/funcs/lock";
in {
  imports =
    [ ../../modules ../../../shared/themes/select.nix ./nomadfuncs.nix ];

  evertras.themes.selected =
    (theme // { fonts = (theme.fonts // fontOverrides); });

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

      git.userEmail = "brandon.fulljames@woven-planet.global";

      funcs = {
        aws-login.body = "aws sso login";
        kitty-gl.body = "nixGLIntel kitty -1";
        alacritty-gl.body = "nixGLIntel alacritty";

        timelapse-center = {
          runtimeInputs = with pkgs; [ ffmpeg-full fira-code ];
          body = ''
            mkdir -p ~/.evertras/timelapses/

            rawfile=~/.evertras/timelapses/timelapse.mp4
            outfile=~/.evertras/timelapses/$(date +"%Y-%m-%d-%H-%M-%S").avi

            rm -f "$rawfile"

            fps=1

            # Record
            ffmpeg \
              -video_size ${displayCenter.resolution} \
              -framerate "$fps" \
              -f x11grab \
              -i :1.0+3840,0 \
              "$rawfile"

            # How fast to speed it up (10x, 20x, etc)
            speedfactor=10

            # Add a timer, speed it up, and convert to AVI
            ffmpeg \
              -i "$rawfile" \
              -r "$speedfactor" \
              -vf "setpts=PTS/$speedfactor,drawtext=\
                fontfile=${pkgs.fira-code}/share/fonts/truetype/FiraCode-VF.ttf: \
                fontsize=32: fontcolor=red: \
                text='%{eif\:n/60\:d}\:%{eif\:mod(n,60)\:d\:2}': \
                x=1970: y=10: \
                box=1: boxborderw=10: boxcolor=0xcccccc" \
              "$outfile"

            mpv "$outfile"
          '';
        };

        timelapse-compare = {
          runtimeInputs = with pkgs; [ ffmpeg-full ];
          body = ''
            #!/bin/bash

            # Check if two arguments are provided
            if [ "$#" -ne 2 ]; then
                echo "Usage: $0 <video1> <video2>"
                exit 1
            fi

            # Assign input filenames to variables
            video1="$1"
            video2="$2"

            # Get the durations of the input videos
            duration1=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video1")
            duration2=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video2")

            # Determine the maximum duration
            max_duration=$(echo "$duration1 $duration2" | awk '{if ($1 > $2) print $1; else print $2}')

            echo "Max duration: $max_duration"

            outputFile=output.avi

            # Combine the videos side-by-side with padding if necessary
            ffmpeg -i "$video1" -i "$video2" -filter_complex "\
            [0:v]tpad=stop_mode=clone:stop_duration=$(echo "$max_duration - $duration1" | bc)[v1]; \
            [1:v]tpad=stop_mode=clone:stop_duration=$(echo "$max_duration - $duration2" | bc)[v2]; \
            [v1][v2]hstack=inputs=2[outv]" \
            -map "[outv]" -c:v libx264 "$outputFile"

            # Inform the user of the output
            echo "The combined video has been saved as $outputFile"
          '';
        };
      };

      asdf.enable = true;
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

          fontSize = terminalFontSize;
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
        i3.enable = true;
        dwm = {
          enable = true;

          autostartCmds = [
            "xrandr --dpi 200 --output HDMI-0 --rotate left && sleep 1 && (/home/brandon-fulljames/.fehbg || feh --bg-fill /home/brandon-fulljames/d/g/e/wallpapers/static/forest-butterflies.jpeg)"
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
      };
    };
  };

  # We have picom already installed and working via Ubuntu,
  # so use it to avoid OpenGL headaches
  services.picom.enable = false;

  # This isn't working properly, so disabling it but keeping it around
  # for reference later if I end up wanting to mess with it again...
  # would want to run 'autorandr -l main' in autostart above if fixed.
  # For now just a manual xrandr setting seems to be enough
  programs.autorandr = {
    enable = false;

    profiles = {
      main = {
        fingerprint = {
          DP-2 =
            "00ffffffffffff00410c0b096a010000171d0104b54628783a5905af4f42af270e5054bd4b00d1c081808140950f9500b30081c001014dd000a0f0703e8030203500ba8e2100001aa36600a0f0701f8030203500ba8e2100001a000000fc0050484c203332385036560a2020000000fd0017501ea03c010a20202020202001fc020326f14b101f04130312021101051423090707830100006d030c00100019782000600102038c0ad08a20e02d10103e9600ba8e21000018011d007251d01e206e285500ba8e2100001e4d6c80a070703e8030203a00ba8e2100001a7d3900a080381f4030203a00ba8e2100001a0000000000000000000000000000000000bf";
          DP-4 =
            "00ffffffffffff0010acbc414c464744141e0104b53c22783eee95a3544c99260f5054a54b00e1c0d100d1c0b300a94081808100714f4dd000a0f0703e803020350055502100001a000000ff00444c56435831330a2020202020000000fd00184b1e8c36010a202020202020000000fc0044454c4c205532373230514d0a0148020319f14c101f2005140413121103020123097f0783010000a36600a0f0703e803020350055502100001a565e00a0a0a029503020350055502100001a114400a0800025503020360055502100001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d9";
          HDMI-0 =
            "00ffffffffffff00410c2909240400000a1d010380351e782aa631a855519d250f5054bfef00d1c0b30095008180814081c001010101023a801871382d40582c45000f282100001e2a4480a070382740302035000f282100001a000000fc0050484c203234314238510a2020000000fd00304c1e5512000a2020202020200165020327f14b101f051404130312021101230907078301000065030c001000681a00000101304c008c0ad08a20e02d10103e96000f2821000018011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f28210000188c0ad090204031200c4055000f282100001800000000000000000000000000000000c4";
        };
        config = {
          # DPI calc: sqrt(width^2 + height^2) / diagInches
          # Note that DPI separate per monitor may not actually work with XOrg,
          # but leaving it here for reference anyway as it doesn't hurt.
          ${displayLeft.name} = {
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
      nixgl.nixGLIntel
      nodejs
      pythonversion."3.9.5"
      vagrant

      wireshark
      termshark
    ];

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
