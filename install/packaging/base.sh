# Install all base packages
mapfile -t packages < <(grep -v '^#' "$PROMETHEUS_INSTALL/prometheus-base.packages" | grep -v '^$')
prometheus-pkg-add "${packages[@]}"