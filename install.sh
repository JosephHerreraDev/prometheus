#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -eEo pipefail

# Define Prometheus locations
export PROMETHEUS_PATH="$HOME/.local/share/prometheus"
export PROMETHEUS_INSTALL="$PROMETHEUS_PATH/install"
export PROMETHEUS_INSTALL_LOG_FILE="/var/log/prometheus-install.log"
export PATH="$PROMETHEUS_PATH/bin:$PATH"

# Install
source "$PROMETHEUS_INSTALL/packaging/all.sh"
source "$PROMETHEUS_INSTALL/config/all.sh"
source "$PROMETHEUS_INSTALL/login/all.sh"