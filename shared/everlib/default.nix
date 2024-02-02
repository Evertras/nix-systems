{ lib }:
with lib;
let concatPaths = base: subdir: base + ("/" + subdir);
in {
  allSubdirs = path:
    let
      # { "fileordirname" = "regular|directory" ... }
      readset = builtins.readDir path;
      dirset = filterAttrs (_: s: s == "directory") readset;
      dirs = map (concatPaths path) (builtins.attrNames dirset);
    in dirs;

  allFiles = path:
    let
      # { "fileordirname" = "regular|directory" ... }
      readset = builtins.readDir path;
      fileset = filterAttrs (_: s: s == "regular") readset;
      files = map (concatPaths path) (builtins.attrNames fileset);
    in files;

  existsOr = a: b: if a == null then b else a;
}
