{ config, lib, pkgs, ... }:
with lib;
let cfg = config.evertras.home.shell.asdf;
in {
  options.evertras.home.shell.asdf = {
    enable = mkEnableOption "asdf version manager";
  };

  config = mkIf cfg.enable {
    home.file = mkIf config.evertras.home.shell.shells.fish.enable {
      ".config/fish/conf.d/asdf.fish" = {
        text = ''
          source ~/.nix-profile/share/asdf-vm/asdf.fish
        '';
      };

      ".asdfrc".text = "legacy_version_file = yes";
    };

    home.packages = with pkgs; [ asdf-vm ];
  };
}
