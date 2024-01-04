{ ... }:

{
  imports = [ ./colorscheme.nix ./plugins.nix ];

  config.programs.nixvim = {
    enable = true;

    globals = { mapleader = ","; };

    autoCmd = [{
      event = "BufEnter";
      pattern = "*.nomad";
      command = "set filetype=hcl";
      desc = "Nomad files are HCL";
    }];

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
        action = "vim.cmd.nohlsearch";
        lua = true;
      }

      {
        mode = "n";
        key = "<leader>f";
        action = "vim.lsp.buf.code_action({apply=true})";
      }

      # TODO: Good chance to learn how to map in nix
      (genNav "H")
      (genNav "J")
      (genNav "K")
      (genNav "L")

      # Filetree
      {
        mode = "n";
        key = "<C-N>";
        action = "vim.cmd.NvimTreeToggle";
        lua = true;
      }
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
