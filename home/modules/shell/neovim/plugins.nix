{ config, lib, ... }:
with lib;
let cfg = config.evertras.home.shell.neovim;
in {
  options.evertras.home.shell.neovim = {
    # Must explicitly enable to avoid running in sensitive environments
    enableCopilot = mkEnableOption "copilot";
  };

  config.programs.nixvim.plugins = {
    gitsigns.enable = true;

    copilot-lua = mkIf cfg.enableCopilot {
      enable = true;

      filetypes = { markdown = true; };

      suggestion = {
        # Experiment with this, may want it off for perf?
        enabled = true;
        autoTrigger = true;

        # Keymaps: https://github.com/nix-community/nixvim/blob/main/plugins/completion/copilot-lua.nix
      };
    };

    nvim-colorizer = { enable = true; };

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

      sections = {
        lualine_b = [ "branch" "diff" "diagnostics" ];
        lualine_c = [ "vim.fn.expand('%:.')" "navic" ];
      };

      inactiveSections = { lualine_c = [ "vim.fn.expand('%:.')" "navic" ]; };
    };

    # Need this for nvim-cmp, revisit later
    luasnip.enable = true;

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

      # Need this for completion to work, revisit later
      snippet.expand = "luasnip";

      mapping = {
        "<C-y>" = "cmp.mapping.confirm({ select = true })";
        "<up>" = "cmp.mapping.select_prev_item()";
        "<down>" = "cmp.mapping.select_next_item()";
        "<C-d>" = "cmp.mapping.scroll_docs(4)";
        "<C-u>" = "cmp.mapping.scroll_docs(-4)";
      };
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
