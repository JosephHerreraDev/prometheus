#!/bin/bash

MAIN_DIRECTORY="$HOME/Pictures"
REPO_URL="https://github.com/JosephHerreraDev/wallpapers.git"
TARGET_DIR="$MAIN_DIRECTORY/wallpapers"

mkdir -p "$MAIN_DIRECTORY"
cd "$MAIN_DIRECTORY" || exit

if [ -d "$TARGET_DIR/.git" ]; then
    echo "Wallpapers already exist, pulling latest changes..."
    git -C "$TARGET_DIR" pull
else
    git clone "$REPO_URL"
fi
