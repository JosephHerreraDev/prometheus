# Copy over Prometheus configs
mv ~/.config ~/.config.bak
mkdir -p ~/.config
# cp -R ~/.local/share/prometheus/config/* ~/.config/

cd ~/.local/share/prometheus/config/
stow -t ~ *

# Use default bashrc from Prometheus
cp ~/.local/share/prometheus/default/bashrc ~/.bashrc
