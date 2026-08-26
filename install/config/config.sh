#!/usr/bin/env bash

set -euo pipefail

# Link the repository's config packages into the user's home directory so
# changes remain synchronized with Git.
PROMETHEUS_ROOT="${PROMETHEUS_PATH:-$HOME/.local/share/prometheus}"
CONFIG_ROOT="$PROMETHEUS_ROOT/config"

if [[ ! -d "$CONFIG_ROOT" ]]; then
  echo "Prometheus config directory not found: $CONFIG_ROOT" >&2
  exit 1
fi

# Keep the previous configuration recoverable without failing when an older
# backup already exists.
if [[ -e "$HOME/.config" || -L "$HOME/.config" ]]; then
  backup="$HOME/.config.bak"
  if [[ -e "$backup" || -L "$backup" ]]; then
    backup="$HOME/.config.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  mv "$HOME/.config" "$backup"
fi

mkdir -p "$HOME/.config"

linked_packages=0
for package_path in "$CONFIG_ROOT"/*; do
  [[ -d "$package_path/.config" ]] || continue
  package="${package_path##*/}"
  stow --dir="$CONFIG_ROOT" --target="$HOME" --restow --no-folding "$package"
  ((linked_packages += 1))
done

if (( linked_packages == 0 )); then
  echo "No Prometheus config packages were found in: $CONFIG_ROOT" >&2
  exit 1
fi

echo "Linked $linked_packages Prometheus config packages into $HOME/.config"

