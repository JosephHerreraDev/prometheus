#!/usr/bin/env bash
set -euo pipefail
# Install all base packages
sudo pacman -Syu --noconfirm
mapfile -t packages < <(
  sed -e 's/\r$//' \
      -e 's/[[:space:]]*$//' \
      -e '/^[[:space:]]*#/d' \
      -e '/^[[:space:]]*$/d' \
      "$PROMETHEUS_INSTALL/prometheus-base.packages"
)
prometheus-pkg-add "${packages[@]}"
