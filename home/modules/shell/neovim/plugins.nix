{ ... }: {
  config.programs.nixvim.plugins = {
    gitsigns.enable = true;

    lsp = {
      enable = true;

      keymaps = {
        lspBuf = {
          "<leader>d" = "definition";
          "K" = "hover";
          "<leader>r" = "references";
          "<leader>h" = "signature_help";
        };
      };
    };

    lualine.enable = true;

    nvim-cmp = {
      enable = true;

      sources = [
        { name = "path"; }
        { name = "nvim_lsp"; }
        {
          name = "nvim_lsp_signature_help";
        }
        #{ name = "buffer"; }
      ];
    };

    nvim-tree.enable = true;

    rust-tools.enable = true;

    telescope = {
      enable = true;
      keymaps = {
        "<leader>gg" = { action = "git_files"; };
        "<leader>gG" = { action = "find_files"; };
      };
    };

    #vim.keymap.set('n', '<leader>gs', function()
    #builtin.grep_string({ search = vim.fn.input("ag > ") });
    #d)

    treesitter = { enable = true; };

    # For other things in the future
    #packer.enable = true;
  };
}
