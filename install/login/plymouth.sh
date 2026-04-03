if [[ $(plymouth-set-default-theme) != "prometheus" ]]; then
  sudo cp -r "$HOME/.local/share/prometheus/default/plymouth" /usr/share/plymouth/themes/prometheus/
  sudo plymouth-set-default-theme prometheus
fi
