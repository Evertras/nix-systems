{ config, pkgs, ... }: {
  config = {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-gtk fcitx5-configtool fcitx5-mozc ];
    };
  };
}
