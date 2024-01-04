{ ... }:

{
  imports = [ ./plugins.nix ];

  config.programs.nixvim = {
    enable = true;

    colorschemes.catppuccin = {
      enable = true;

      flavour = "mocha";

      transparentBackground = true;
    };

    globals = { mapleader = ","; };

    keymaps = let
      genNav = key: {
        mode = "n";
        key = "<C-${key}>";
        action = "<C-W><C-${key}>";
      };
    in [
      {
        mode = "i";
        key = "jk";
        action = "<Esc>";
      }

      {
        mode = "n";
        key = ";";
        action = ":";
      }

      {
        mode = "n";
        key = "<leader><space>";
        options.expr = true;
        action = "vim.cmd.nohlsearch";
      }

      # TODO: Good chance to learn how to map in nix
      (genNav "H")
      (genNav "J")
      (genNav "K")
      (genNav "L")
    ];

    options = {
      number = true;
      relativenumber = true;

      # Find search results as we type
      incsearch = true;

      shiftwidth = 2;

      mouse = "";

      # Split down-right instead of up-left
      splitright = true;
      splitbelow = true;
    };
  };
}
