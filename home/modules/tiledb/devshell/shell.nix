{ pkgs ? import <nixpkgs> { } }:
let
  # To find revisions, example with helm:
  # https://lazamar.co.uk/nix-versions/?channel=nixos-25.05&package=helm

  pinPkg = { rev, sha }:
    import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
      sha256 = if sha == "" then
        "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
      else
        sha;
    }) { config.allowUnfree = true; };

  # 3.12.0
  pkgHelm = pinPkg {
    rev = "c23b26e93eb86808ca17a2974eca2d701cb05ed4";
    sha = "sha256:1sns59f0412rrxvj8g4c1xv5fnwng72rsyv6lq7g6wzfcdh4s5m9";
  };

  # 1.27.0
  pkgKubectl = pinPkg {
    rev = "351cec5db3b7ca839779316a8b7c524ea8941f0f";
    sha = "sha256:1fibpqj7y27fp5i231v3fxchr1ngvg37iv0a9hlfr5p4p5cgbq5g";
  };

  # 1.5.7
  pkgTerraform = pinPkg {
    rev = "4415dfb27cfecbe40a127eb3e619fd6615731004";
    sha = "sha256:06f4rs71cgpisx6kic1inaj25s2gg8pclvz20b0cn191vmh5hkns";
  };

  # 0.16.0
  pkgTerraformDocs = pinPkg {
    rev = "4f8f3ddb2ae8a978244a211780610471a7931b4e";
    sha = "sha256:06f4rs71cgpisx6kic1inaj25s2gg8pclvz20b0cn191vmh5hkns";
  };
in pkgs.mkShell {
  buildInputs = with pkgs; [
    #(python3.withPackages (ps: with ps; [ setuptools wheel pip ]))
    # Don't manage any packages here for now, all in venv
    python3

    # Build tools
    cmake
    pkg-config
    vcpkg

    # Build dependencies
    gcc
    stdenv.cc.cc.lib
    zstd
    pkg-config

    # Reasonably latest tools
    argocd
    awscli
    pre-commit

    # Pinned tools
    pkgHelm.helm
    pkgKubectl.kubectl
    pkgTerraform.terraform
    pkgTerraformDocs.terraform-docs
  ];

  shellHook = let
    tiledb-home-dir = "\${XDG_DATA_HOME:-$HOME/.local/share}/tiledb";
    venv_dir = "$HOME/.evertras/venv/tiledb";
  in ''
    export CGO_CFLAGS="-I${tiledb-home-dir}/include";
    export CGO_LDFLAGS="-L${tiledb-home-dir}/lib64";
    export TILEDB_HOME="${tiledb-home-dir}";
    export TILEDB_PATH="${tiledb-home-dir}";
    export TILEDB_DEV_DATA="${tiledb-home-dir}/devdata";
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$TILEDB_HOME/lib64"

    if [ ! -d "${venv_dir}" ]; then
      echo "Creating tiledb virtual environment"
      python3 -m venv "${venv_dir}"
    fi

    source "${venv_dir}/bin/activate"

    echo "TileDB shell activated"
  '';

  venvDir = "/home/evertras/.evertras/venv/tiledb";
}
