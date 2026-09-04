#!/usr/bin/env bash
set -euo pipefail
bash "$PROMETHEUS_INSTALL/config/config.sh"
PROMETHEUS_INSTALLING=1 bash "$PROMETHEUS_INSTALL/config/theme.sh"
bash "$PROMETHEUS_INSTALL/config/mimetypes.sh"
