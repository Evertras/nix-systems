{ theme, palette }:
let
  layout = ''
    padding: 0 0.5em;
    margin: 0;
  '';
  mkBorder = color: "border-top: 3px solid ${color}";
in ''
  /* NOTE: this rule overrides things
    at random, use with caution despite
    it being in the doc example...
  */
  * {
    border: none;
    min-height: 0;
  }

  window#waybar {
    background: ${theme.colors.background};
    color: ${theme.colors.text};
    font-family: ${theme.fonts.main.name}, Helvetica, Arial, sans-serif;
    font-size: 18px;
  }

  #battery {
    ${layout}
    color: ${palette.Sapphire};
    background-color: ${theme.colors.background};
    ${mkBorder palette.Sapphire};
  }

  #battery.low {
    color: ${theme.colors.background};
    background-color: ${theme.colors.urgent};
    border-color: ${theme.colors.urgent};
  }

  #bluetooth {
    ${layout}
    background-color: ${theme.colors.background};
    color: ${palette.Blue};
    ${mkBorder palette.Blue};
  }

  #bluetooth.connected {
    background-color: ${palette.Blue};
    color: ${theme.colors.background};
  }

  #clock {
    ${layout}
    background-color: ${theme.colors.background};
    color: ${palette.Sapphire};
    ${mkBorder palette.Sapphire};
  }

  #network {
    ${layout}
    color: ${theme.colors.background};
  }

  #network.disconnected {
    background-color: ${theme.colors.urgent};
  }

  #network.wifi {
    color: ${palette.Lavender};
    background-color: ${theme.colors.background};
    ${mkBorder palette.Lavender};
  }

  #pulseaudio {
    ${layout}
    color: ${palette.Rosewater};
    ${mkBorder palette.Rosewater};
    min-width: 3em;
  }

  #pulseaudio.bluetooth {
    color: ${palette.Blue};
    ${mkBorder palette.Blue};
  }

  #pulseaudio.muted {
    color: ${theme.colors.urgent};
    ${mkBorder theme.colors.urgent};
  }

  #window {
    background-color: ${theme.colors.background};
    color: ${theme.colors.contrast};
    padding: 0 1em;
  }

  #workspaces {
    margin: 0;
    border-radius: 0;
  }

  #workspaces button {
    margin: 0;
    padding-left: 0.3em;
    padding-right: 0.3em;
    padding-top: 0.1em;
    padding-bottom: 0.1em;
    ${mkBorder theme.colors.primary};
    border-radius: 0;
    color: ${theme.colors.primary};
    background-color: ${theme.colors.background};
  }

  #workspaces button.empty {
  }

  #workspaces button.visible {
  }

  #workspaces button.active {
    color: ${theme.colors.background};
    background-color: ${theme.colors.primary};
  }

  #workspaces button.urgent {
    color: ${theme.colors.background};
    background-color: ${theme.colors.urgent};
    border-color: ${theme.colors.urgent};
  }
''
