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

    colorizer = {
      enable = true;

      settings = {
        user_default_options = {
          # Don't highlight things like "Red" or "Blue" or "Microsoft Azure"
          names = false;
        };
      };
    };

    lsp = {
      enable = true;

      keymaps = {
        diagnostic = {
          "<leader>e" = "open_float";
          "<leader>j" = "goto_next";
          "<leader>k" = "goto_prev";
        };

        lspBuf = {
          "<leader>d" = "definition";
          "K" = "hover";
          "<leader>r" = "references";
          "<leader>h" = "signature_help";
        };
      };

      # https://github.com/nix-community/nixvim/blob/10d114f5a6e0a9591d13a28a92905e71cc100b39/plugins/lsp/language-servers/default.nix
      servers = let langs = config.evertras.home.shell.coding;
      in {
        bashls.enable = true;
        cssls.enable = true;
        gopls.enable = true;
        # Specific check for now due to being multiple gigabytes
        hls.enable = langs.haskell.enable;
        html.enable = true;
        lua_ls.enable = true;
        nil_ls.enable = true;
        svelte.enable = true;
        terraformls.enable = true;
        ts_ls.enable = true;
        yamlls.enable = true;
      };
    };

    lualine = let
      filename = [{
        __unkeyed-1 = "filename";

        # Show relative path
        path = 1;
      }];
    in {
      enable = true;

      settings = {
        sections = {
          lualine_b = filename;
          lualine_c = [ "diagnostics" ];
          lualine_x = [ "filesize" ];
        };

        inactive_sections = {
          lualine_b = filename;
          lualine_c = [ "diagnostics" ];
          lualine_x = [ "filesize" ];
        };
      };
    };

    luasnip = {
      enable = true;

      fromLua = [{ paths = ./snippets; }];
    };

    cmp = {
      enable = true;

      settings = {
        sources = [
          { name = "path"; }
          { name = "luasnip"; }
          { name = "nvim_lsp"; }
          { name = "nvim_lsp_signature_help"; }
        ];

        # Need this for completion to work, revisit later
        snippet.expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body)
          end
        '';

        mapping = {
          "<C-y>" = "cmp.mapping.confirm({ select = true })";
          "<up>" = "cmp.mapping.select_prev_item()";
          "<down>" = "cmp.mapping.select_next_item()";
          "<C-d>" = "cmp.mapping.scroll_docs(4)";
          "<C-u>" = "cmp.mapping.scroll_docs(-4)";
        };
      };
    };

    nvim-tree = {
      enable = true;

      sortBy = "case_sensitive";

      filters.dotfiles = true;

      openOnSetup = true;

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

    web-devicons.enable = true;

    rainbow-delimiters.enable = true;

    rustaceanvim.enable = true;

    telescope = {
      enable = true;
      keymaps = {
        "<leader>gg" = { action = "git_files"; };
        "<leader>gG" = { action = "find_files"; };
      };
    };

    treesitter = { enable = true; };
  };
}
