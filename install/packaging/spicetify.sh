#!/usr/bin/env bash

set -euo pipefail

SPICETIFY_INSTALL_URL="https://raw.githubusercontent.com/spicetify/cli/main/install.sh"


# Install spicetify (safe re-run)
if ! command -v spicetify >/dev/null 2>&1; then
    curl -fsSL "$SPICETIFY_INSTALL_URL" | sh
else
    echo "Spicetify already installed. Updating..."
    spicetify upgrade
fi

# Ensure spotify exists
if ! command -v spotify-launcher >/dev/null 2>&1; then
    echo "Spotify not found. Install it first."
    exit 1
fi

# Initialize config if needed
spicetify