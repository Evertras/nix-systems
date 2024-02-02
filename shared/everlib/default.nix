{ lib }:
with lib; {
  allSubdirs = rootPath:
    let
      # { "fileordirname" = "regular|directory" ... }
      readset = builtins.readDir rootPath;
      dirset = filterAttrs (_: type: type == "directory") readset;
      dirs = map (path.append rootPath) (builtins.attrNames dirset);
    in dirs;

  allNixFiles = rootPath:
    let
      # { "fileordirname" = "regular|directory" ... }
      readset = builtins.readDir rootPath;
      isNixFile = strings.hasSuffix ".nix";
      fileset =
        filterAttrs (filename: type: (isNixFile filename) && type == "regular")
        readset;
      files = map (path.append rootPath) (builtins.attrNames fileset);
    in files;

  existsOr = a: b: if a == null then b else a;
}
