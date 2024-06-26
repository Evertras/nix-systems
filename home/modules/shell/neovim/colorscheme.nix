{ ... }:

{
  config.programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;

      settings = {
        # Italic doesn't render nicely on some displays
        disable_italic = true;

        flavour = "frappe";

        transparent_background = true;

        # Show up better on transparent/dark backgrounds
        custom_highlights = ''
          function(colors)
            return {
              Comment = { fg = colors.overlay1 },
              LineNr = { fg = colors.sky },
            }
          end
        '';
      };
    };
  };
}
