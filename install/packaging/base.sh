# Install all base packages
sudo pacman -Syu --noconfirm
mapfile -t packages < <(grep -v '^#' "$PROMETHEUS_INSTALL/prometheus-base.packages" | grep -v '^$')
prometheus-pkg-add "${packages[@]}"