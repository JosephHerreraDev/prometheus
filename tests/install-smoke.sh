#!/usr/bin/env bash
# No package installation or desktop session required.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export HOME="$work/home"
export PROMETHEUS_PATH="$work/source tree"
mkdir -p "$HOME/.config/example" "$HOME/.config/unrelated" "$PROMETHEUS_PATH/config/example/.config/example" "$PROMETHEUS_PATH/bin"
printf old > "$HOME/.config/example/settings"
printf keep > "$HOME/.config/unrelated/settings"
printf new > "$PROMETHEUS_PATH/config/example/.config/example/settings"
printf hidden > "$PROMETHEUS_PATH/config/example/.config/example/.hidden"
bash "$repo/install/config/config.sh"
[[ $(cat "$HOME/.config/example/settings") == new ]]
[[ $(cat "$HOME/.config/example/.hidden") == hidden ]]
[[ $(cat "$HOME/.config/unrelated/settings") == keep ]]
[[ ! -L "$HOME/.config/example/settings" ]]
backups=("$HOME"/.local/state/prometheus/config-backup.*/.config/example/settings)
[[ $(cat "${backups[0]}") == old ]]
bash "$repo/install/config/config.sh"
[[ $(grep -Fc 'source "$HOME/.config/prometheus/environment.sh"' "$HOME/.bashrc") == 1 ]]
source "$HOME/.config/prometheus/environment.sh"
[[ $PROMETHEUS_PATH == "$work/source tree" ]]

# A failed package stage must stop the orchestration before subsequent stages.
export PROMETHEUS_INSTALL="$work/install stages"
mkdir -p "$PROMETHEUS_INSTALL/packaging"
printf 'exit 17\n' > "$PROMETHEUS_INSTALL/packaging/base.sh"
printf 'touch "$HOME/should-not-exist"\n' > "$PROMETHEUS_INSTALL/packaging/aur.sh"
cp "$PROMETHEUS_INSTALL/packaging/aur.sh" "$PROMETHEUS_INSTALL/packaging/backgrounds.sh"
if bash "$repo/install/packaging/all.sh"; then
  echo 'Package failure was swallowed' >&2; exit 1
fi
[[ ! -e "$HOME/should-not-exist" ]]

# Generate the real supplied theme without requiring Hyprland or notifications.
export PROMETHEUS_PATH="$repo"
export PATH="$repo/bin:$PATH"
bash "$repo/install/config/config.sh"
[[ -f "$HOME/.config/hypr/hyprland.lua" ]]
[[ -f "$HOME/.config/quickshell/shell.qml" ]]
export PROMETHEUS_INSTALLING=1
bash "$repo/install/config/theme.sh"
[[ $(cat "$HOME/.config/prometheus/current/theme.name") == nord ]]
[[ -f "$HOME/.config/prometheus/current/theme/Theme.qml" ]]
echo 'Installer smoke tests passed.'
