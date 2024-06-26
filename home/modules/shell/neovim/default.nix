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
        pattern = "*.tfvars";
        command = "set filetype=hcl";
        desc = "Terraform variable files are HCL";
      }
      {
        event = "BufEnter";
        pattern = "*";
        command = "set formatoptions-=cro";
        desc =
          "Don't automatically create comment leads on new lines after a comment";
      }
      {
        event = [ "BufWinEnter" "BufWinEnter" ];
        pattern = "*";
        command = "set foldlevel=99";
        desc = "Start unfolded";
      }
      {
        event = "BufWrite";
        pattern = "*.go";
        callback.__raw = "function() vim.lsp.buf.format() end";
        desc = "Format go files on write";
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
        action.__raw = "vim.cmd.nohlsearch";
      }

      # Format
      {
        mode = "n";
        key = "<leader>F";
        action.__raw = "vim.lsp.buf.format";
      }

      # Rename
      {
        mode = "n";
        key = "<leader>R";
        action.__raw = "vim.lsp.buf.rename";
      }

      # Filetree
      {
        mode = "n";
        key = "<C-N>";
        action.__raw = "vim.cmd.NvimTreeToggle";
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

    opts = {
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

    # Things we can't do anywhere else... the keymaps above get
    # a little grouchy with complicated lua keymap formatting.
    extraConfigLua = ''
      vim.keymap.set('n', '<leader>gs', function() require('telescope.builtin').grep_string({ search = vim.fn.input("ag > ") }); end)
      local function quickfix()
        vim.lsp.buf.code_action({apply = true})
      end
      vim.keymap.set('n', '<leader>f', quickfix)

      local luasnip = require('luasnip')
      vim.keymap.set({ 'i', 's' }, '<C-j>', function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end)
      vim.keymap.set({ 'i', 's' }, '<C-k>', function()
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        end
      end)
    '';
  };
}
