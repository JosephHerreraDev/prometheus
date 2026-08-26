#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define Prometheus locations
export PROMETHEUS_PATH="$HOME/.local/share/prometheus"
export PROMETHEUS_INSTALL="$PROMETHEUS_PATH/install"
export PROMETHEUS_INSTALL_LOG_FILE="/var/log/prometheus-install.log"
export PATH="$PROMETHEUS_PATH/bin:$PATH"

# Bootstrap the dotfile linker before the larger package transaction. This
# ensures the Git-backed configuration is installed even if an optional
# package fails later.
if ! command -v stow >/dev/null 2>&1; then
  sudo pacman -Syu --needed --noconfirm stow
fi

bash "$PROMETHEUS_INSTALL/config/config.sh"

# Install the remaining software, then apply configuration that depends on it.
source "$PROMETHEUS_INSTALL/packaging/all.sh"
bash "$PROMETHEUS_INSTALL/config/theme.sh"
bash "$PROMETHEUS_INSTALL/config/mimetypes.sh"
