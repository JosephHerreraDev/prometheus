#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail
trap 'echo "Installation failed at line $LINENO: $BASH_COMMAND" >&2' ERR
if [[ $(uname -s) != Linux ]] || ! command -v pacman >/dev/null; then
  echo "Run this installer on Arch Linux." >&2
  exit 1
fi
if (( EUID == 0 )); then
  echo "Run as your regular user, without sudo." >&2
  exit 1
fi
sudo -v

# Define Prometheus locations
export PROMETHEUS_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PROMETHEUS_INSTALL="$PROMETHEUS_PATH/install"
export PROMETHEUS_INSTALL_LOG_FILE="/var/log/prometheus-install.log"
export PATH="$PROMETHEUS_PATH/bin:$PATH"

chmod +x "$PROMETHEUS_PATH"/bin/*
bash "$PROMETHEUS_INSTALL/packaging/all.sh"
bash "$PROMETHEUS_INSTALL/config/all.sh"
echo "Installation complete. Log out and select Hyprland to use the configuration."
