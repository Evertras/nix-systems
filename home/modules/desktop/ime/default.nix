{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.desktop.ime;
in {
  options.evertras.home.desktop.ime = {
    enable = mkEnableOption "extra input methods (IME)";
  };

  config = mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      # At some point try to figure out settings here.
      # https://mynixos.com/nixpkgs/options/i18n.inputMethod.fcitx5.settings
      # A first try got an error about that field not existing.
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-gtk
          fcitx5-configtool
          fcitx5-mozc
          fcitx5-nord
        ];
      };
    };

    evertras.home.shell.funcs = {
      # Some day it would be nice to make this a package,
      # or use the NUR, but we're already doing some
      # custom config anyway.
      "fcitx5-install-catppuccin".body = ''
        git clone https://github.com/catppuccin/fcitx5.git /tmp/fcitx5-catppuccin
        mkdir -p ~/.local/share/fcitx5/themes/
        cp -r /tmp/fcitx5-catppuccin/src/* ~/.local/share/fcitx5/themes
      '';
    };
  };
}
