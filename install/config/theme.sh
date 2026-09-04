#!/usr/bin/env bash
set -euo pipefail
# Setup user theme folder
mkdir -p ~/.config/prometheus/themes

# Set initial theme
prometheus-theme-set "Nord"

# Set specific app links for current theme
mkdir -p ~/.config/btop/themes
ln -snf ~/.config/prometheus/current/theme/btop.theme ~/.config/btop/themes/current.theme
mkdir -p ~/.config/quickshell
if [[ -d ~/.config/quickshell/theme && ! -L ~/.config/quickshell/theme ]]; then
  rm -f ~/.config/quickshell/theme/Theme.qml
  rmdir ~/.config/quickshell/theme 2>/dev/null || {
    echo "Could not replace ~/.config/quickshell/theme; directory is not empty"
    exit 1
  }
fi
ln -snf ~/.config/prometheus/current/theme ~/.config/quickshell/theme

mkdir -p ~/.config/zathura
ln -snf ~/.config/prometheus/current/theme/theme.zathurarc ~/.config/zathura/zathurarc
