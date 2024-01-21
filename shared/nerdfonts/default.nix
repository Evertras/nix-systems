{ pkgs }:
let
  # For whatever reason, the sha names aren't always the font names...
  # https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/data/fonts/nerdfonts/shas.nix
  shaMapping = {
    "3270" = "3270";
    "Agave" = "Agave";
    "AnonymicePro" = "AnonymousPro";
    "AurulentSansM" = "AurulentSansMono";
    "BigBlueTerm437" = "BigBlueTerminal";
    "BigBlueTermPlus" = "BigBlueTerminal";
    "BitstromWera" = "BitstromVerySansMono";
    "CaskaydiaCove" = "CascadiaCode";
    "CodeNewRoman" = "CodeNewRoman";
    "ComicShannsMono" = "ComicShannsMono";
    "Cousine" = "Cousine";
    "DaddyTimeMono" = "DaddyTimeMono";
    "DejaVuSansM" = "DejaVuSansMono";
    "DroidSansM" = "DroidSansMono";
    "EnvyCodeR" = "EnvyCodeR";
    "FantasqueSansM" = "FantasqueSansMono";
    "FiraCode" = "FiraCode";
    "FiraCodeMono" = "FiraCode";
    "GohuFont 11" = "Gohu";
    "GohuFont 14" = "Gohu";
    "GohuFont uni11" = "Gohu";
    "GohuFont uni14" = "Gohu";
    "GoMono" = "Go-Mono";
    "Hack" = "Hack";
    "Hasklug" = "Hasklig";
    "Hurmit" = "Hermit";
    "iMWritingMono" = "iA-Writer";
    "InconsolataGo" = "InconsolataGo";
    "Inconsolata LGC" = "InconsolataLGC";
    "Inconsolata" = "Inconsolata";
    "IntoneMono" = "IntelOneMono";
    "Iosevka" = "Iosevka";
    "IosevkaTerm" = "IosevkaTerm";
    "JetBrainsMono" = "JetBrainsMono";
    "JetBrainsMonoNL" = "JetBrainsMono";
    "Lekton" = "Lekton";
    "Lilex" = "Lilex";
    "LiterationMono" = "LiberationMono";
    "M+1Code" = "MPlus";
    "M+CodeLat" = "MPlus";
    "M+CodeLatX" = "MPlus";
    "MesloLGL" = "Meslo";
    "MesloLGLDZ" = "Meslo";
    "MesloLGM" = "Meslo";
    "MesloLGMDZ" = "Meslo";
    "MesloLGS" = "Meslo";
    "MesloLGSDZ" = "Meslo";
    "Monofur" = "Monofur";
    "Monoid" = "Monoid";
    "Mononoki" = "Mononoki";
    "NotoMono" = "Noto";
    "NotoSansM" = "Noto";
    "OpenDyslexicM" = "OpenDyslexic";
    "OverpassM" = "Overpass";
    "ProFont IIx" = "ProFont";
    "ProFontWindows" = "ProFont";
    "ProggyClean CE" = "ProggyClean";
    "ProggyClean" = "ProggyClean";
    "ProggyCleanSZ" = "ProggyClean";
    "RobotoMono" = "RobotoMono";
    "SauceCodePro" = "SourceCodePro";
    "ShureTechMono" = "ShareTechMono";
    "SpaceMono" = "SpaceMono";
    "Symbols" = "NerdFontsSymbolsOnly";
    "Terminess" = "Terminus";
    "UbuntuMono" = "UbuntuMono";
    "VictorMono" = "VictorMono";
  };
in {
  make = name: {
    name = "${name} Nerd Font";
    package = pkgs.nerdfonts.override { fonts = [ shaMapping.${name} ]; };
  };

  makeMono = name: {
    name = "${name} Nerd Font Mono";
    package = pkgs.nerdfonts.override { fonts = [ shaMapping.${name} ]; };
  };
}
