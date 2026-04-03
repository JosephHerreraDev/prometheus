# Copy over Prometheus configs
mkdir -p ~/.config
# cp -R ~/.local/share/prometheus/config/* ~/.config/

cd ~/.local/share/prometheus/config/
stow */

# Use default bashrc from Omarchy
cp ~/.local/share/prometheus/default/bashrc ~/.bashrc
