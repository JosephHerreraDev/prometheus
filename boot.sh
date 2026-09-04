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

if [[ -t 1 && -n ${TERM:-} ]]; then clear; fi
echo -e "\n$ansi_art\n"

DEST="$HOME/.local/share"
TARGET="$DEST/prometheus"

command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }

mkdir -p "$DEST"
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  echo "Using existing checkout: $TARGET"
  [[ -f "$TARGET/install.sh" ]] || { echo "No installer found in $TARGET" >&2; exit 1; }
else
  git clone https://github.com/JosephHerreraDev/prometheus.git "$TARGET"
fi
cd "$TARGET"

echo -e "\nInstallation starting..."
bash ./install.sh
