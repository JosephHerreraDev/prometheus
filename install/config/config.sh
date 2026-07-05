# Copy over Prometheus configs
mv ~/.config ~/.config.bak
mkdir -p ~/.config

cd ~/.local/share/prometheus/config/
stow -t ~ *

