#!/usr/bin/env bash

set -e

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

DEST="$HOME/.local/share"
TARGET="$DEST/prometheus"

command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }

rm -rf "$TARGET"
mkdir -p "$DEST"
git clone https://github.com/JosephHerreraDev/prometheus.git "$TARGET"
cd "$TARGET"

echo -e "\nInstallation starting..."
./install.sh