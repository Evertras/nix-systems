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

      onAttach = ''
        if client.server_capabilities.documentSymbolProvider then
          require("nvim-navic").attach(client, bufnr)
        end
      '';

      # https://github.com/nix-community/nixvim/blob/10d114f5a6e0a9591d13a28a92905e71cc100b39/plugins/lsp/language-servers/default.nix
      servers = let langs = config.evertras.home.shell.coding;
      in {
        bashls.enable = true;
        cssls.enable = true;
        gopls.enable = true;
        helm_ls.enable = true;
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

      settings = let
        breadcrumb = {
          # Custom logic for navigating larger files like helm chart values,
          # where we want to see what root key we're in.
          __unkeyed-1.__raw = ''
            function()
              local navic = require("nvim-navic")
              local data = navic.get_data() or {}

              if #data == 0 then return "" end

              -- How many keys to show at the start when limit is reached
              local limitPrefix = 4
              -- How many keys to show at the end when limit is reached
              local limitSuffix = 2
              local limit = limitPrefix + limitSuffix
              local hlSep = "%#LineNr#"
              local hlRoot = "%#Directory#"
              local hlLeaf = "%#Type#"
              local hlComment = "%#Comment#"
              local hlTerm = "%*"
              local sep = hlSep .. "." .. hlTerm

              if #data == 1 then return hlLeaf .. data[1].name .. hlTerm end

              local root = hlRoot .. data[1].name .. hlTerm
              local leaf = hlLeaf .. data[#data].name .. hlTerm

              local parts = {
                root
              }

              if #data <= limit then
                for i = 2, #data-1 do
                  table.insert(parts, data[i].name)
                end
                table.insert(parts, leaf)
              else
                parts = {
                  root,
                }

                for i = 2, limitPrefix do
                  table.insert(parts, data[i].name)
                end

                table.insert(parts, hlComment .. "..." .. hlTerm)

                local start = #data - limitSuffix + 1
                for i = start, #data-1 do
                  table.insert(parts, data[i].name)
                end
                table.insert(parts, leaf)
              end

              return table.concat(parts, sep)
            end
          '';

          cond.__raw =
            "function () return require('nvim-navic').is_available() end";
        };
      in {
        sections = {
          lualine_b = filename;
          lualine_c = [ "diagnostics" ];
          lualine_x = [ breadcrumb ];
          lualine_y = [ "filesize" ];
        };

        inactive_sections = {
          lualine_b = filename;
          lualine_c = [ "diagnostics" ];
          lualine_x = [ breadcrumb ];
          lualine_y = [ "filesize" ];
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

    navic = {
      enable = true;
      settings = {
        depth_limit = 5;
        highlight = true;
        # Use CursorHold instead of CursorMoved, enable if it starts feeling laggy
        # lazy_update_context = true;
        lsp.autoAttach = true;
        separator = ">";
      };
    };

    nvim-tree = {
      enable = true;

      openOnSetup = true;

      settings = {
        filters.dotfiles = true;

        sort_by = "case_sensitive";

        on_attach = {
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

    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        ensure_installed = [ "gotmpl" "helm" "lua" "yaml" ];
      };
    };
  };
}
