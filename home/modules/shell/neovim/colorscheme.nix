{ ... }:

{
  config.programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;

      flavour = "mocha";

      transparentBackground = true;

      # Show up better on transparent/dark backgrounds
      customHighlights = ''
        function(colors)
          return {
            Comment = { fg = colors.flamingo },
            LineNr = { fg = colors.sky },
          }
        end
      '';
    };
  };
}
