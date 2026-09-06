#!/usr/bin/env bash
set -euo pipefail

PROMETHEUS_ROOT="${PROMETHEUS_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
CONFIG_ROOT="$PROMETHEUS_ROOT/config"
[[ -d "$CONFIG_ROOT" ]] || { echo "Config directory missing: $CONFIG_ROOT" >&2; exit 1; }
command -v stow >/dev/null 2>&1 || { echo "GNU Stow is required." >&2; exit 1; }
backup_root=""
backup_target() {
  if [[ -z $backup_root ]]; then
    mkdir -p "$HOME/.local/state/prometheus"
    backup_root=$(mktemp -d "$HOME/.local/state/prometheus/config-backup.XXXXXXXX")
    echo "Previous configuration saved in $backup_root"
  fi
  local relative="${1#"$HOME/"}"
  mkdir -p "$backup_root/$(dirname -- "$relative")"
  mv -- "$1" "$backup_root/$relative"
}

# Preserve conflicting copies/links before Stow takes ownership. Keep target
# directories real so generated theme files never end up in the checkout.
prepare_tree() {
  local source=$1 target=$2 entry destination
  if [[ -L "$target" || ( -e "$target" && ! -d "$target" ) ]]; then
    backup_target "$target"
  fi
  mkdir -p "$target"
  for entry in "$source"/*; do
    destination="$target/${entry##*/}"
    if [[ -d "$entry" && ! -L "$entry" ]]; then
      prepare_tree "$entry" "$destination"
    elif [[ -e "$destination" || -L "$destination" ]]; then
      # Already managed by this checkout: leave it for --restow.
      if [[ -L "$destination" && $(readlink -f -- "$destination") == "$(readlink -f -- "$entry")" ]]; then
        continue
      fi
      backup_target "$destination"
    fi
  done
}
shopt -s nullglob dotglob
packages=()
for package_path in "$CONFIG_ROOT"/*; do
  [[ -d "$package_path/.config" ]] || continue
  packages+=("${package_path##*/}")
done
(( ${#packages[@]} > 0 )) || { echo "No configuration packages found." >&2; exit 1; }
for package in "${packages[@]}"; do
  prepare_tree "$CONFIG_ROOT/$package" "$HOME"
done
stow --dir="$CONFIG_ROOT" --target="$HOME" --no-folding --restow "${packages[@]}"

# Persist the helper path for subsequent Bash login and interactive sessions.
mkdir -p "$HOME/.config/prometheus"
environment_file="$HOME/.config/prometheus/environment.sh"
if [[ -e "$environment_file" || -L "$environment_file" ]]; then
  backup_target "$environment_file"
fi
printf 'export PROMETHEUS_PATH=%q\nexport PATH="$PROMETHEUS_PATH/bin:$HOME/.local/bin:$PATH"\n' "$PROMETHEUS_ROOT" > "$environment_file"
for profile in "$HOME/.bashrc" "$HOME/.bash_profile"; do
  line='source "$HOME/.config/prometheus/environment.sh"'
  if ! grep -Fqx "$line" "$profile" 2>/dev/null; then
    printf '\n%s\n' "$line" >> "$profile"
  fi
done
# Archives may not preserve executable modes on Quickshell helpers.
if [[ -d "$HOME/.config/quickshell" ]]; then
  find "$CONFIG_ROOT/quickshell" -type f -name '*ctl' -exec chmod +x {} +
fi
echo "Stowed ${#packages[@]} configuration packages into $HOME"
