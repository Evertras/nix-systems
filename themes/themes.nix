# Defines a bunch of constants for use in other
# modules to create a consistent theme that can be
# easily switched
let
  defaultFonts = {
    main = { name = "Terminess Nerd Font"; };
    mono = { name = "Terminess Nerd Font Mono"; };
    desktop = { name = "ComicShannsMono Nerd Font"; };
  };

  # For ideas: https://www.gnome-look.org/browse?cat=135&ord=rating
  # For names: use nix-find-theme-names
  # Fun ones to go back to:
  # orchis-theme / Orchis-Purple-Dark-Compact
  defaultGtkTheme = {
    name = "Layan-Dark";
    packageName = "layan-gtk-theme";
  };

  # For names: use nix-find-cursor-names
  # Fun ones to go back to:
  # nordzy-cursor-theme / Nordzy-cursors-white
  defaultCursorTheme = {
    name = "Bibata-Modern-Ice";
    packageName = "bibata-cursors";
  };
in {
  mint = {
    # https://coolors.co/ef6f6c-2e394d-dcf9eb-59c9a5-7a907c
    colors = {
      primary = "#59C9A5";
      highlight = "#A7F1CD";
      background = "#2E394D";
      text = "#DCF9EB";
      urgent = "#EF6F6C";
    };

    fonts = defaultFonts;

    cursorTheme = defaultCursorTheme;
    gtkTheme = defaultGtkTheme;
  };

  mountain = {
    colors = {
      primary = "#9A8493";
      highlight = "#E7D2C5";
      background = "#223843";
      text = "#EFF1F3";
      urgent = "#D2694B";
    };

    fonts = defaultFonts;

    cursorTheme = defaultCursorTheme;
    gtkTheme = defaultGtkTheme;
  };
}
