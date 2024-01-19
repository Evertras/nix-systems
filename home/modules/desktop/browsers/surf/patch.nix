{ }: {
  mkPatch = { }:

    builtins.toFile "ever-surf.diff" "";
}
