#!/usr/bin/env bash

set -e

if ! type nixfmt &>/dev/null; then
  echo "WARNING: Skipping format step, no nixfmt found"
  exit 0
fi

# https://prettier.io/docs/en/precommit.html#option-6-shell-script
FILES=$(git diff --cached --name-only --diff-filter=ACMR | sed 's| |\\ |g')
[ -z "$FILES" ] && exit 0

# Prettify all selected files
echo "$FILES" | xargs nixfmt

# Add back the modified/prettified files to staging
echo "$FILES" | xargs git add
