{ ... }: {
  evertras.home.shell.funcs = {
    git-merged.body = ''
      branch=$(git rev-parse --abbrev-ref HEAD)

      if [ "''${branch}" == "main" ]; then
        echo "Cannot run this on main branch!"
        exit 1
      fi

      git checkout main
      git pull
      git branch -d "''${branch}"
    '';

    # TODO: Handle spaces in file names, for notes repositories in particular
    gadd.body = ''
      to_add=$(git status --porcelain | awk '/^.M/ || /^\?\?/ {print $2}' | fzf --scheme=path -i --tiebreak=end --preview 'git diff --color {+1}')
      if [ -n "$to_add" ]; then
        git add "$to_add"
        echo "Added $to_add"
      fi
    '';
  };
}
