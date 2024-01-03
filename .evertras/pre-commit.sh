#!/usr/bin/env bash

set -e

if ! type nixfmt &>/dev/null; then
  # nixfmt is annoying to install outside of nix, so don't
  # lock ourselves out of tweaking things
  echo "WARNING: Skipping format step, no nixfmt found"
  exit 0
fi

# Only look at changed files
files=$(git diff --cached --name-only --diff-filter=ACMR | sed 's| |\\ |g')
[ -z "${files}" ] && exit 0

IFS=$'\n'
for file in ${files}; do
  if ! nixfmt -c "${file}" &>/dev/null; then
    nixfmt "${file}"
    git add "${file}"
    echo "${file} -> FORMATTED"
  else
    echo "${file} -> ok"
  fi
done
