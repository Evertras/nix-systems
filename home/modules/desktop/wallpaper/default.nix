{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.evertras.home.desktop.wallpaper;
in
{
  options.evertras.home.desktop.wallpaper = {
    # For now just awww, but add others in this subdir later if we want
    enable = mkEnableOption "Enable wallpaper manager via awww";

    internalOutputRegex = mkOption {
      type = types.str;
      default = "^(eDP|LVDS|DSI)";
      description = ''
        Outputs matching this are the built in laptop panel, everything else
        is treated as external.  Outputs are discovered from awww at runtime
        rather than hardcoded, so a display keeps working when the kernel
        renames it (DP-2 -> DP-1 after a dock or firmware change).
      '';
    };

    randomWallpapersDir = mkOption {
      type = types.str;
      default = "~/.evertras/wallpapers/";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ awww ];

    systemd.user =
      let
        rotateServiceName = "evertras-wallpaper-rotate";
        rotateFuncName = "wallpaper-external-random";
        rotateFunc = config.evertras.home.shell.funcPackages.${rotateFuncName};
      in
      {
        timers.${rotateServiceName} = {
          Unit.Description = "Wallpaper rotator";

          Timer = {
            OnBootSec = "5min";
            OnUnitActiveSec = "5min";
            Unit = "${rotateServiceName}.service";
          };

          Install.WantedBy = [ "timers.target" ];
        };

        services.${rotateServiceName} = {
          Unit = {
            Description = "Rotate wallpapers";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            Type = "oneshot";
            # WAYLAND_DISPLAY comes from the compositor importing it into the
            # systemd user environment, so don't pin a socket name here.
            ExecStart = "${rotateFunc}/bin/${rotateFuncName}";
          };
        };
      };

    evertras.home.shell.funcs =
      let
        funcPkgs = config.evertras.home.shell.funcPackages;

        deps = with pkgs; [
          awww
          coreutils
          gawk
          gnugrep
        ];

        # awww query prints one line per connected output:
        #
        #   ": DP-1: 4267x1800, scale: 1.2, currently displaying: color: 000000"
        #    ^ namespace, empty by default
        #      ^ output name
        listConnected = "awww query | awk -F': ' '{ print $2 }'";

        # Select the outputs to act on.  grepArgs is "-v" to invert, i.e. to
        # pick the externals.  Matching whole lines matters here: a substring
        # match for DP-1 would also hit eDP-1.
        #
        # A failing query means the daemon is down and should fail loudly, so
        # only the grep gets an || true - matching nothing is normal.
        selectOutputs = grepArgs: ''
          connected=$(${listConnected})
          outputs=$(echo "$connected" | grep -E ${grepArgs} '${cfg.internalOutputRegex}' || true)

          if [ -z "$outputs" ]; then
            echo "No matching displays connected.  awww sees: $(echo "$connected" | tr '\n' ' ')"
            exit 0
          fi
        '';

        # Run cmd once per selected output, with $output set each time.
        forEach = grepArgs: cmd: ''
          ${selectOutputs grepArgs}

          while read -r output; do
            ${cmd}
          done <<< "$outputs"
        '';

        mkSwitch = grepArgs: {
          runtimeInputs = deps;
          body = ''
            if [ "$#" -ne 1 ]; then
              echo "Usage: $(basename "$0") <image-file>" >&2
              exit 1
            fi

            ${forEach grepArgs ''awww img -o "$output" "$1"''}
          '';
        };

        mkRandom = grepArgs: {
          runtimeInputs = deps ++ [ funcPkgs.random-file ];
          # A separate pick per output, so two monitors don't end up matching.
          body = forEach grepArgs ''awww img -o "$output" "$(random-file ${cfg.randomWallpapersDir})"'';
        };

        mkClear = grepArgs: {
          runtimeInputs = deps;
          body = forEach grepArgs ''awww clear -o "$output" 000000'';
        };

        internal = "";
        external = "-v";
      in
      mkIf cfg.enable {
        # Handy on its own for checking what awww currently sees
        wallpaper-outputs = {
          runtimeInputs = deps;
          body = listConnected;
        };

        wallpaper-laptop = mkSwitch internal;
        wallpaper-laptop-random = mkRandom internal;
        wallpaper-external = mkSwitch external;
        wallpaper-external-random = mkRandom external;
        wallpaper-external-black = mkClear external;
      };
  };
}
