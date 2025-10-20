{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    #(python3.withPackages (ps: with ps; [ setuptools wheel pip ]))
    # Don't manage any packages here for now, all in venv
    python3

    gcc
    stdenv.cc.cc.lib
    zstd
    pkg-config
  ];

  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$TILEDB_HOME/lib64"

    source ~/.evertras/venv/tiledb/bin/activate

    echo "TileDB shell activated"
  '';

  venvDir = "/home/evertras/.evertras/venv/tiledb";
}

