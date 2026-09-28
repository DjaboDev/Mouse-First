#!/usr/bin/env bash
# Symlink this checkout over the installed Mouse-First plugin for development.
# The previous install is moved aside, never deleted. Nothing else is touched.
set -euo pipefail

id="io.github.mousefirst.controls"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="$HOME/.config/omarchy/plugins/$id"

if [[ -L "$target" && "$(readlink -f "$target")" == "$repo" ]]; then
  echo "Already linked: $target -> $repo"
  exit 0
fi

mkdir -p "$(dirname "$target")"
if [[ -e "$target" || -L "$target" ]]; then
  backup="$HOME/.local/state/omarchy/backups/$id.$(date +%Y%m%d%H%M%S)"
  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  echo "Moved the existing install to $backup"
fi

ln -s "$repo" "$target"
echo "Linked $target -> $repo"
echo "Run 'omarchy restart shell' to load it."
