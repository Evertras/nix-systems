{ pkgs, ... }:
let
  # https://pkg.go.dev/time#pkg-constants
  logTimeFormat = "2006-01-02 15:04:05 MST";
in {
  evertras.home.shell.funcs = {
    funcs = {
      runtimeInputs = with pkgs; [ eza ];
      body = ''
        eza -1 ~/.evertras/funcs
      '';
    };

    # Outside of code because I want to use this with ASDF on a non-NixOS system
    # without installing Go, but it does feel odd
    go-watch-test = {
      runtimeInputs = with pkgs; [ entr fzf ];
      body = ''
        base="''${1:-.}"

        watchdir=$(find "$base" -name '*.go' -exec dirname {} \; | sort -u | fzf --scheme=path -i --tiebreak=end)

        if [ -z "$watchdir" ]; then
          echo "No directory selected"
          exit 1
        fi

        while sleep 1; do find "$watchdir" -iname '*.go' | entr -c -d go test -race -count=1 "./$watchdir"; done
      '';
    };

    log-info = {
      runtimeInputs = with pkgs; [ gum ];
      body = ''
        gum log -t "${logTimeFormat}" -l info "$*"
      '';
    };

    log-error = {
      runtimeInputs = with pkgs; [ gum ];
      body = ''
        gum log -t "${logTimeFormat}" -l error "$*"
      '';
    };

    log-warn = {
      runtimeInputs = with pkgs; [ gum ];
      body = ''
        gum log -t "${logTimeFormat}" -l warn "$*"
      '';
    };

    log-fatal = {
      runtimeInputs = with pkgs; [ gum ];
      body = ''
        gum log -t "${logTimeFormat}" -l fatal "$*"
      '';
    };

    nix-explore = {
      runtimeInputs = with pkgs; [ eza ];
      body = ''
        if [ "$1" == "" ]; then
          echo "USAGE: nix-explore <nixpkgs-package-name>"
          echo ""
          echo "       Explores the contents of a Nix package's output path"
          echo "       using eza's tree view.  Useful for exploring what's"
          echo "       in a package's output path."
          echo ""
          echo "   ex: nix-explore 'ripgrep'"
          exit 1
        fi

        paths=$(nix build "nixpkgs#''${1}" --print-out-paths --no-link)

        while IFS= read -r path || [[ -n "$path" ]]; do
          eza --tree "$path"
        done <<< "$paths"
      '';
    };

    nix-dev-init = {
      body = ''
        if [ -f flake.nix ]; then
          log-fatal "flake.nix already exists"
        fi

        cat > flake.nix <<EOF
        {
          inputs = {
            # TODO: Update if necessary
            nixpkgs.url = "nixpkgs/nixos-25.05";
            flake-utils.url = "github:numtide/flake-utils";
          };

          outputs = { self, nixpkgs, flake-utils }:
            flake-utils.lib.eachDefaultSystem (system:
              let
                pkgs = import nixpkgs { inherit system; };
              in
              {
                devShells.default = pkgs.mkShell {
                  packages = with pkgs; [
                    # Dev tools
                    hello
                  ];
                };
              });
        }
        EOF
      '';
    };

    replace-all.body = ''
      if [ $# -ne 4 ]; then
        echo "USAGE: change-all <dir> <file-filter> <old-regex> <replacement>"
        echo ""
        echo "       Changes all matches of <old-regex> to <new> in the"
        echo "       <dir> directory and all subdirectories for all files"
        echo "       that match the file-type filter.  Uses sed."
        echo ""
        echo "   ex: change-all '*.go' 'mypkg\.Thing' 'mypkg.BetterName'"
        exit 1
      fi

      dir=$1
      filefilter=$2
      oldregex=$3
      replacement=$4

      echo "Looking in all files with filter '$filefilter'"

      # Show all matches for thorough check with fzf for scrolling
      matches=$(find "$dir" -type f -name "$filefilter" -exec grep -nE "$oldregex" {} +)
      echo "$matches" | fzf --no-sort

      # Show affected files with counts for quick final check when deciding
      find "$dir" -type f -name "$filefilter" -exec grep -cE "$oldregex" {} + | awk -F: '$2 != 0 { print $2 " " $1 }' | col | sort -n

      echo "Replacing any regex pattern match of '$oldregex' with '$replacement' in $dir"
      read -p "Found $(wc -l <<< "$matches") matches.  Continue? [y/n] " -n 1 -r
      echo ""

      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Don't do it"
        exit 1
      fi

      find "$dir" -type f -name "$filefilter" -exec sed -i "s/$oldregex/$replacement/g" {} \;
    '';

    trim-ending-newline.body = ''
      sed ':a;N;$!ba;s/\n$//'
    '';
  };
}
