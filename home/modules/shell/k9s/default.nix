{ config, lib, ... }:
with lib;
let cfg = config.evertras.home.shell.k9s;
in {
  options.evertras.home.shell.k9s = { enable = mkEnableOption "k9s"; };

  config = mkIf cfg.enable {
    programs.k9s = {
      enable = true;

      settings = {
        # I'm paranoid for now
        readOnly = true;

        skin = "catppuccin-frappe";
      };

      skins = {
        catppuccin-frappe = ./skins/catppuccin-frappe.yaml;
        catppuccin-frappe-transparent =
          ./skins/catppuccin-frappe-transparent.yaml;

        catppuccin-mocha = ./skins/catppuccin-mocha.yaml;
        catppuccin-mocha-transparent =
          ./skins/catppuccin-mocha-transparent.yaml;

        catppuccin-macchiato = ./skins/catppuccin-macchiato.yaml;
        catppuccin-macchiato-transparent =
          ./skins/catppuccin-macchiato-transparent.yaml;

        catppuccin-latte = ./skins/catppuccin-latte.yaml;
        catppuccin-latte-transparent =
          ./skins/catppuccin-latte-transparent.yaml;
      };
    };
  };
}
