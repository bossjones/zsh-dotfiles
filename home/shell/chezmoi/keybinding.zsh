#!/usr/bin/env zsh

if [[ "$OSTYPE" == darwin* ]]
then
    _ARCH=$(uname -m)
    if [[ "${_ARCH}" = "arm64" ]]
    then
        _MY_PATH_TO_FZF_KEYBINDINGS=/opt/homebrew/opt/fzf/shell/key-bindings.zsh
    else
        _MY_PATH_TO_FZF_KEYBINDINGS=/usr/local/opt/fzf/shell/key-bindings.zsh
    fi
    
    _MY_PATH_TO_FZF_KEYBINDINGS=$HOME/.fzf/shell/key-bindings.zsh
fi

source "${_MY_PATH_TO_FZF_KEYBINDINGS}"
