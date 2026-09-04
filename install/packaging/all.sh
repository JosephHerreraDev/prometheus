#!/usr/bin/env bash
set -euo pipefail
bash "$PROMETHEUS_INSTALL/packaging/base.sh"
bash "$PROMETHEUS_INSTALL/packaging/aur.sh"
bash "$PROMETHEUS_INSTALL/packaging/backgrounds.sh"
