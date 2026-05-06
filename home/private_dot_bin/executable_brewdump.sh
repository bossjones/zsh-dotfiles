#!/usr/bin/env zsh

# SOURCE: https://github.com/satococoa/dotfiles/blob/main/brewdump.sh

set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
BREWFILE="$DIR/Brewfile"

if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed." >&2
    exit 1
fi

echo "Dumping Brewfile to $BREWFILE..."
brew bundle dump --describe --force --no-vscode --no-go --file "$BREWFILE"
