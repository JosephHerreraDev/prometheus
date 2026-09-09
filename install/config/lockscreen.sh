#!/usr/bin/env bash
set -euo pipefail

PROMETHEUS_ROOT="${PROMETHEUS_PATH:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}"
target_theme=/usr/share/sddm/themes/prometheus
staging=$(mktemp -d)
trap 'rm -rf -- "$staging"' EXIT
python3 "$PROMETHEUS_ROOT/default/lockscreen/render.py" "$staging"
cp -a "$PROMETHEUS_ROOT/default/sddm" "$staging/theme"
cp "$staging/Style.qml" "$staging/theme/Style.qml"
background="${1:-$HOME/.config/prometheus/current/background}"
if [[ -f "$background" ]]; then
  cp -L -- "$background" "$staging/theme/background.jpg"
else
  # Both renderers fall back to the shared solid background.
  sed -i '\|    path = /usr/share/sddm/themes/prometheus/background.jpg|d' "$staging/hyprlock.conf"
  sed -i 's/source: "background.jpg"/source: ""/' "$staging/theme/Main.qml"
fi
cat > "$staging/sddm.conf" <<'CONFIG'
[Theme]
Current=prometheus
CONFIG

sudo install -d -m 755 "$target_theme" /usr/share/prometheus /etc/sddm.conf.d
sudo cp -a "$staging/theme/." "$target_theme/"
sudo chown -R root:root "$target_theme"
sudo chmod -R a+rX "$target_theme"
sudo install -m 644 "$staging/hyprlock.conf" /usr/share/prometheus/hyprlock.conf
# /etc/sddm.conf takes precedence over drop-ins. Preserve it before updating
# just the keys needed by this theme, leaving all other settings intact.
if sudo test -f /etc/sddm.conf; then
  sudo cp -a /etc/sddm.conf "/etc/sddm.conf.prometheus-backup.$(date +%s%N)"
  sudo python3 - "$staging/sddm.conf" <<'PY'
import configparser
import sys
from pathlib import Path
path = Path('/etc/sddm.conf')
config = configparser.ConfigParser(interpolation=None, strict=False)
config.optionxform = str
config.read(path)
overrides = configparser.ConfigParser(interpolation=None)
overrides.optionxform = str
overrides.read(sys.argv[1])
for section in overrides.sections():
    if not config.has_section(section):
        config.add_section(section)
    config[section].update(overrides[section])
with path.open('w') as output:
    config.write(output)
PY
fi
sudo install -m 644 "$staging/sddm.conf" /etc/sddm.conf.d/zz-prometheus.conf
echo "Installed matching Prometheus SDDM and hyprlock themes. SDDM will use it at the next login."
