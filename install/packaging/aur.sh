#!/bin/bash
set -euo pipefail

# Install base dependencies for building AUR packages
sudo pacman -S --needed --noconfirm base-devel git

# Install yay if not installed
if ! command -v yay &> /dev/null; then
  build_dir=$(mktemp -d)
  trap 'rm -rf -- "$build_dir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
  cd "$build_dir/yay"
  makepkg -si --noconfirm
  cd "$PROMETHEUS_INSTALL"
fi

mapfile -t packages < <(
  sed -e 's/\r$//' \
      -e 's/[[:space:]]*$//' \
      -e '/^[[:space:]]*#/d' \
      -e '/^[[:space:]]*$/d' \
      "$PROMETHEUS_INSTALL/prometheus-aur.packages"
)
prometheus-pkg-aur-add "${packages[@]}"
