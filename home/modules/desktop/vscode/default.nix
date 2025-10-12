{ config, everlib, lib, ... }:
with everlib;
with lib;
let
  cfg = config.evertras.home.desktop.vscode;
  theme = config.evertras.themes.selected;
in {
  options.evertras.home.desktop.vscode = {
    enable = mkEnableOption "vscode";

    fontName = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;

      profiles.default = {
        enableUpdateCheck = false;

        # Extensions are handled by user manually, tried to do definitions
        # here but A) it's annoying and B) it broke, so...

        userSettings = {
          "vim.insertModeKeyBindings" = [{
            before = [ "j" "k" ];
            after = [ "<Esc>" ];
          }];
          "editor.autoClosingBrackets" = "never";
          "workbench.colorTheme" = "Catppuccin Macchiato";
          "explorer.confirmDragAndDrop" = false;
          "makefile.configureOnOpen" = true;
          "explorer.confirmDelete" = false;
          "github.copilot.nextEditSuggestions.enabled" = true;
          "editor.fontFamily" = "${
              existsOr cfg.fontName theme.fonts.terminal.name
            }, 'Courier New', monospace";
        };

        keybindings = [
          {
            "key" = "ctrl+shift+alt+i";
            "command" = "extension.vim_ctrl+i";
            "when" =
              "editorTextFocus && vim.active && vim.use<C-i> && !inDebugRepl";
          }
          {
            "key" = "ctrl+i";
            "command" = "-extension.vim_ctrl+i";
            "when" =
              "editorTextFocus && vim.active && vim.use<C-i> && !inDebugRepl";
          }
        ];
      };
    };
  };
}
