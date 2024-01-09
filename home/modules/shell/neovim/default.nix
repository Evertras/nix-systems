{ ... }:

{
  imports = [ ./colorscheme.nix ./plugins.nix ];

  config.programs.nixvim = {
    enable = true;

    globals = { mapleader = ","; };

    autoCmd = [
      {
        event = "BufEnter";
        pattern = "*.nomad";
        command = "set filetype=hcl";
        desc = "Nomad files are HCL";
      }
      {
        event = "BufEnter";
        pattern = "*";
        command = "set formatoptions-=cro";
        desc =
          "Don't automatically create comment leads on new lines after a comment";
      }
      {
        event = "BufEnter";
        pattern = "*";
        command = "normal zz";
        desc = "Start unfolded";
      }
    ];

    keymaps = let
      # Jump between panes more easily
      keymapsNav = map (key: {
        mode = "n";
        key = "<C-${key}>";
        action = "<C-W><C-${key}>";
      }) [ "H" "J" "K" "L" ];
    in keymapsNav ++ [
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

      # Filetree
      {
        mode = "n";
        key = "<C-N>";
        action = "vim.cmd.NvimTreeToggle";
        lua = true;
      }

      # Folding
      {
        mode = "n";
        key = "<space>";
        action = "za";
      }
      {
        mode = "n";
        key = "zz";
        action = "zR";
      }
    ];

    options = {
      # Line numbers are relative
      number = true;
      relativenumber = true;

      # Find search results as we type
      incsearch = true;

      # If we don't have editorconfig, keep tabs at 2
      shiftwidth = 2;

      # No mouse
      mouse = "";

      # Split down-right instead of up-left
      splitright = true;
      splitbelow = true;

      # Keep some buffer at the bottom so we can see more context
      scrolloff = 8;

      # Folding
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
    };

    # Things we can't do anywhere else
    extraConfigLua = ''
      vim.keymap.set('n', '<leader>gs', function() require('telescope.builtin').grep_string({ search = vim.fn.input("ag > ") }); end)
    '';
  };
}
