{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.tmux;
in {
  options.evertras.home.tmux = { enable = mkEnableOption "tmux"; };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      # Always want tmuxinator with tmux
      tmuxinator.enable = true;

      # TODO: just copy/pasted old config, revisit what's needed
      extraConfig = ''
        # Some tweaks to the status line
        set -g window-status-current-style underscore

        # If running inside tmux ($TMUX is set), then change the status line to red
        %if #{TMUX}
        set -g status-bg red
        %endif

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

        # Synchronize input to all panes, toggled
        bind s setw synchronize-panes

        # Turn off repeat entirely so we can instantly type after moving
        set -g repeat-time 0

        # Turn escape time to tiny so we can quickly escape in vim without breaking tmux
        set -g escape-time 20

        # Statusbar formatting
        set -g status-position bottom
        set -g status-justify left
        set -g status-left ""
        set -g status-right-length 55
        set -g status-left-length 30

        set -g status-style bg=default,fg=colour137
        set -g status-right '#[fg=#5DB7DE,bg=colour237] %H:%M #[fg=#5DB7DE,bg=colour235] %m/%d '
        setw -g window-status-current-style fg=colour255,bg='#5DB7DE',none
        setw -g window-status-current-format '#[fg=colour255,bg=#5DB7DE] #I #[fg=colour235]#W #{?window_zoomed_flag,#[fg=#ff0000]Z ,}#[fg=#5DB7DE,bg=colour232]'
        setw -g window-status-style fg=colour255,bg=colour065,none
        setw -g window-status-format ' #I #[fg=colour232]#W '

        setw -g pane-border-format '#[fg=#888888]'
        setw -g pane-border-status bottom

        setw -g pane-active-border-style 'fg=#5Db7DE'

        setw -g window-status-bell-style fg=colour255,bg=colour1,bold

        # Start from one so it's easier to switch
        set -g base-index 1

        # Turn focus events on for GitGutter in Vim
        set -g focus-events on

        # Machine-specific settings
        source-file ~/.tmux.local.conf
      '';
    };
  };
}
