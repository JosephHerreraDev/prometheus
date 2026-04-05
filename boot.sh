#!/bin/bash

ansi_art=$(cat <<'EOF'
    ___       ___       ___       ___       ___       ___       ___       ___       ___       ___   
   /\  \     /\  \     /\  \     /\__\     /\  \     /\  \     /\__\     /\  \     /\__\     /\  \  
  /::\  \   /::\  \   /::\  \   /::L_L_   /::\  \    \:\  \   /:/__/_   /::\  \   /:/ _/_   /::\  \ 
 /::\:\__\ /::\:\__\ /:/\:\__\ /:/L:\__\ /::\:\__\   /::\__\ /::\/\__\ /::\:\__\ /:/_/\__\ /\:\:\__\
 \/\::/  / \;:::/  / \:\/:/  / \/_/:/  / \:\:\/  /  /:/\/__/ \/\::/  / \:\:\/  / \:\/:/  / \:\:\/__/
    \/__/   |:\/__/   \::/  /    /:/  /   \:\/  /   \/__/      /:/  /   \:\/  /   \::/  /   \::/  / 
             \|__|     \/__/     \/__/     \/__/               \/__/     \/__/     \/__/     \/__/  
EOF
)

clear
echo -e "\n$ansi_art\n"

#rm -rf ~/.local/share/prometheus/
#git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/prometheus >/dev/null

cd ~/.local/share/prometheus
git fetch
cd -

echo -e "\nInstallation starting..."
source ~/.local/share/prometheus/install.sh