{ lib }:
with lib; {
  allSubdirs = path:
    let
      # { "fileordirname" = "regular|directory" ... }
      readset = builtins.readDir path;
      dirset = filterAttrs (_: type: type == "directory") readset;
      dirs = map (path.append path) (builtins.attrNames dirset);
    in dirs;

  allNixFiles = path:
    let
      # { "fileordirname" = "regular|directory" ... }
      readset = builtins.readDir path;
      isNixFile = strings.hasSuffix ".nix";
      fileset =
        filterAttrs (filename: type: (isNixFile filename) && type == "regular")
        readset;
      files = map (path.append path) (builtins.attrNames fileset);
    in files;

  existsOr = a: b: if a == null then b else a;
}
