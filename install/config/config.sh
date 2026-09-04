#!/usr/bin/env bash
set -euo pipefail

PROMETHEUS_ROOT="${PROMETHEUS_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
CONFIG_ROOT="$PROMETHEUS_ROOT/config"
[[ -d "$CONFIG_ROOT" ]] || { echo "Config directory missing: $CONFIG_ROOT" >&2; exit 1; }
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

# Merge directories and preserve unrelated settings. Replace old Stow links
# without following them into the source repository.
copy_tree() {
  local source=$1 target=$2 entry destination
  if [[ -L "$target" || ( -e "$target" && ! -d "$target" ) ]]; then
    backup_target "$target"
  fi
  mkdir -p "$target"
  for entry in "$source"/*; do
    if [[ -d "$entry" && ! -L "$entry" ]]; then
      copy_tree "$entry" "$target/${entry##*/}"
    else
      destination="$target/${entry##*/}"
      if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ ! -L "$destination" && -f "$destination" ]] && cmp -s "$entry" "$destination"; then
          continue
        fi
        backup_target "$destination"
      fi
      cp -a -- "$entry" "$destination"
    fi
  done
}
shopt -s nullglob dotglob
copied_packages=0
for package_path in "$CONFIG_ROOT"/*; do
  [[ -d "$package_path/.config" ]] || continue
  copy_tree "$package_path/.config" "$HOME/.config"
  ((copied_packages += 1))
done
(( copied_packages > 0 )) || { echo "No configuration packages found." >&2; exit 1; }

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
  find "$HOME/.config/quickshell" -type f -name '*ctl' -exec chmod +x {} +
fi
echo "Copied $copied_packages configuration packages into $HOME/.config"
