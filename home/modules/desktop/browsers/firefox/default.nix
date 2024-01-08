{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.desktop.browsers.firefox;
in {
  options.evertras.home.desktop.browsers.firefox = {
    enable = mkEnableOption "firefox";
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      # Keeping this for reference, but not going down this
      # rabbit hole just yet.
      # See https://github.com/nix-community/NUR to enable.
      /* profiles = {
           default = {
             extensions = with config.nur.repos.rycee.firefox-addons;
               [ firefox-color ];
           };
         };
      */
    };
  };
}
