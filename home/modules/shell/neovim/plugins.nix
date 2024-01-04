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

      # https://github.com/nix-community/nixvim/blob/10d114f5a6e0a9591d13a28a92905e71cc100b39/plugins/lsp/language-servers/default.nix
      servers = {
        bashls.enable = true;
        cssls.enable = true;
        gopls.enable = true;
        html.enable = true;
        lua-ls.enable = true;
        rnix-lsp.enable = true;
        terraformls.enable = true;
        tsserver.enable = true;
        yamlls.enable = true;
      };
    };

    lualine = {
      enable = true;

      sections = { lualine_x = [ "navic" ]; };

      inactiveSections = { };
    };

    navic = {
      enable = true;

      lsp.autoAttach = true;
    };

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

    nvim-tree = {
      enable = true;

      sortBy = "case_sensitive";

      filters.dotfiles = true;

      onAttach = {
        __raw = ''
          function(bufnr)
            local api = require("nvim-tree.api")
            local function opts(desc)
              return {
                desc = "nvim-tree: " .. desc,
                buffer = bufnr,
                noremap = true,
                silent = true,
                nowait = true,
              }
            end

            -- Apply defaults first
            api.config.mappings.default_on_attach(bufnr)

            -- Now our stuff
            vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
            vim.keymap.set('n', 's', api.node.open.vertical, opts('Open: Vertical split'))
            vim.keymap.set('n', 'i', api.node.open.horizontal, opts('Open: Horizontal split'))
          end
        '';
      };
    };

    rainbow-delimiters.enable = true;

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
