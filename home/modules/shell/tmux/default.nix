{ config, lib, ... }:
with lib;
let
  cfg = config.evertras.home.shell.tmux;
  colors = config.evertras.themes.selected.colors;
  shellBin = config.evertras.home.shell.core.shellBin;
in {
  options.evertras.home.shell.tmux = {
    enable = mkEnableOption "tmux";
    shell = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      # Always want tmuxinator with tmux
      tmuxinator.enable = true;

      shell = if cfg.shell == null then shellBin else cfg.shell;

      extraConfig = ''
        # Enable RGB colour if running in xterm(1)
        set-option -sa terminal-overrides ",xterm*:Tc"

        # Change the default $TERM to tmux to support italics
        set -g default-terminal "tmux-256color"

        # No bells at all
        set -g bell-action none

        # Keep windows around after they exit
        set -g remain-on-exit on

        # Change the prefix key to C-a
        set -g prefix C-a
        unbind C-b
        bind C-a send-prefix

        # Show windows in collapsed mode
        bind w choose-tree -Zs

        # Turn the mouse on, but without copy mode dragging
        set -g mouse on
        unbind -n MouseDrag1Pane
        unbind -Tcopy-mode MouseDrag1Pane
        unbind -T copy-mode-vi MouseDragEnd1Pane

        # Easier movement, vim-style
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Quicker resizes
        bind C-h resize-pane -L 5
        bind C-j resize-pane -D 5
        bind C-k resize-pane -U 5
        bind C-l resize-pane -R 5

        # Synchronize input to all panes, toggled
        bind s setw synchronize-panes

        # Turn off repeat entirely so we can instantly type after moving
        set -g repeat-time 0

        # Turn off escape time to so we can quickly escape in vim without breaking tmux
        set -g escape-time 0

        # Statusbar formatting
        set -g status-position bottom
        set -g status-justify left
        set -g status-left ""
        set -g status-right-length 55
        set -g status-left-length 30

        # NOTE: This multiplies everything apparently
        set -g status-style bg=default,fg=#ffffff
        set -g status-right '#[fg=${colors.primary}] %H:%M %m/%d '
        set -g window-status-current-style 'fg=${colors.background},bg=${colors.primary},none'
        set -g window-status-current-format ' #I #W #{?window_zoomed_flag,#[fg=${colors.urgent}]Z ,}'
        set -g window-status-style 'fg=${colors.primary},bg=${colors.background},none'
        set -g window-status-format ' #I #[fg=${colors.text}]#W '

        setw -g pane-border-format '#[fg=${colors.primary}]'
        setw -g pane-border-status bottom

        setw -g pane-active-border-style 'fg=${colors.highlight}'

        setw -g window-status-bell-style fg=colour255,bg=colour1,bold

        # When selecting different windows
        set -g mode-style 'fg=${colors.background},bg=${colors.primary}'

        # Start from one so it's easier to switch
        set -g base-index 1

        # Turn focus events on for neovim
        set -g focus-events on
      '';
    };
  };
}

