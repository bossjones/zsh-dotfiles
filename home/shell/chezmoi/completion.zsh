#!/usr/bin/env zsh

mkdir -p  ~/.zsh/completion || true
chezmoi completion zsh --output=~/.zsh/completion/_chezmoi
fpath+=("$HOME/.zsh/completions")