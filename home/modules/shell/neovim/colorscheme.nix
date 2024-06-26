{ ... }:

{
  config.programs.nixvim = {
    colorschemes.catppuccin.settings = {
      enable = true;

      # Italic doesn't render nicely on some displays
      disableItalic = true;

      flavour = "frappe";

      transparentBackground = true;

      # Show up better on transparent/dark backgrounds
      customHighlights = ''
        function(colors)
          return {
            Comment = { fg = colors.overlay1 },
            LineNr = { fg = colors.sky },
          }
        end
      '';
    };
  };
}
