{ config, ... }: {
  evertras.home.shell.funcs = let theme = config.evertras.themes.selected;
  in {
    # Theme helpers for things we can't set directly
    theme-slack.body = let colors = theme.colors;
    in ''
      # Slack doesn't have any nice config, but we want to make it uniform with everything else...
      # we can import by copying this string
      #      background, selected, presence, notifications
      theme="${colors.background},${colors.primary},${colors.highlight},${colors.urgent}"
      echo "$theme" | xclip -selection clipboard
      echo "Theme copied to clipboard"
      echo "$theme"
    '';
    theme-firefox.body = "xdg-open https://github.com/catppuccin/firefox";
    theme-librewolf.body = "xdg-open https://github.com/catppuccin/firefox";

    fonts.body =
      "fc-list : family | awk -F, '{print $1}' | grep Nerd | grep -E 'Mono$' | sort -fu";

    show-color.body = ''
      perl -e 'foreach $a(@ARGV){print "\e[48:2::".join(":",unpack("C*",pack("H*",$a)))."m \e[49m "};print "\n"' "$@"
    '';

    # This is maddening to find otherwise... note this
    # also works for icons
    nix-find-cursor-names.body = ''
      if [ -z "$1" ]; then
        echo "Usage: nix-find-cursor-names <pkgname>"
        return
      fi
      package=$1
      storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
      echo "Store path: ''${storepath}"
      ls "''${storepath}/share/icons"
    '';
    nix-find-theme-names.body = ''
      if [ -z "$1" ]; then
        echo "Usage: nix-find-theme-names <pkgname>"
        return
      fi
      package=$1
      storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
      echo "Store path: ''${storepath}"
      ls "''${storepath}/share/themes"
    '';
    nix-find-icon-names.body = ''
      storepath=${theme.iconTheme.package};
      themename=${theme.iconTheme.name};
      iconspath="''${storepath}/share/icons/''${themename}"
      echo "Store path: ''${storepath}"
      find "''${iconspath}" -name '*.svg' | awk -F/ '{print $NF}' | awk -F. '{print $1}' | sort -u | fzf -i
    '';
    nix-find-icon-names-in.body = ''
      if [ -z "$2" ]; then
        echo "Usage: nix-find-icon-name-in <pkgname> <theme-name>"
        return
      fi
      package=$1
      themename=$2
      storepath=$(nix eval -f '<nixpkgs>' --raw "''${package}")
      iconspath="''${storepath}/share/icons/''${themename}"
      echo "Store path: ''${storepath}"
      find "''${iconspath}" -name '*.svg' | awk -F/ '{print $NF}' | awk -F. '{print $1}' | sort -u | fzf -i
    '';
  };
}
