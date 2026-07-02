{
  config,
  lib,
  nerdfonts,
  pkgs,
  ...
}:
let
  themes = import ../../../shared/themes/themes.nix { inherit pkgs lib; };
  theme = themes.mkCatppuccin { color = "Green"; };

  fontOverrides = {
    main = nerdfonts.make "CaskaydiaCove";
    terminal = nerdfonts.make "Hasklug";
  };

  gpgKey = "57F346A9FC11B688";
  wirelessInterface = "wlp0s20f3";
  externalOutput = "DP-2";
in
{
  imports = [
    ../../modules
    ../../../shared/themes/select.nix
  ];

  evertras.themes.selected = (theme // { fonts = (theme.fonts // fontOverrides); });

  evertras.home = {
    core.username = "evertras";

    tiledb.enable = true;

    audio = {
      enable = true;
      enableDesktop = true;
      headphonesMacAddress = "EC:66:D1:B8:95:88";
      volumeLimit = 60;
    };

    laptop = {
      enable = true;
    };

    shell = {
      core = { inherit gpgKey; };

      coding = {
        go.enable = true;
        nodejs.enable = true;
        rust.enable = true;
      };

      # Read-only GitHub MCP server, run as part of the dockerized MCP fleet
      # (bring it up with `mcp-up`).  Its definition lives in the main repo.
      mcp.github.enable = true;

      claude-sandbox.profiles.nix = {
        dirs = [
          "$HOME/dev/github/evertras/nix"
          "$HOME/dev/github/evertras/nix-tdb"
        ];

        # Join the fleet network so claude can reach the GitHub MCP server by
        # DNS over HTTP, while staying isolated from the host.
        network = config.evertras.home.shell.mcp.network;
        mcp = [ config.evertras.home.shell.mcp.claude.paths.github ];
      };

      funcs = {
        copy.body = ''
          if [ -n "''${1:-}" ]; then
            src="$1"
          else
            src=$(mktemp)
            trap 'rm -f "$src"' EXIT
            cat > "$src"
          fi
          wl-copy < "$src"
          echo -n "Char count: "
          wc --chars "$src" | awk '{print $1}'
          cat "$src"
        '';
      };
    };

    desktop = {
      enable = true;

      bars.waybar = {
        battery.name = "BAT0";
        monitorNetworkInterface = wirelessInterface;
      };

      display.sleep.enable = true;

      discord.enable = true;

      notifications.timeoutSeconds.kitty = 1;

      terminals.kitty = {
        fontName = fontOverrides.terminal.name;
        fontSize = 12;
        opacity = 1;
      };

      wallpaper = {
        randomWallpapersDir = "~/dev/github/evertras/wallpapers/external-rotation";

        outputs.external = externalOutput;
      };

      windowmanager = {
        niri = {
          enable = true;
          borderWidthPixels = 2;
          scaleMain = 1;
        };
      };
    };
  };

  home = {
    packages = with pkgs; [
      packer
      slack
    ];

    # Don't change this, this is the initial install version
    stateVersion = "23.05"; # Please read the comment before changing.
  };
}
