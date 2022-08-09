#!/usr/bin/env zsh

if [[ "$OSTYPE" == darwin* ]]
then
    _ARCH=$(uname -m)
    if [[ "${_ARCH}" = "arm64" ]]
    then
        _MY_PATH_TO_FZF=/opt/homebrew/opt/fzf/bin
    else
        _MY_PATH_TO_FZF=/usr/local/opt/fzf/bin
    fi
    
    _MY_PATH_TO_FZF=$HOME/.fzf/bin
fi

path+="${_MY_PATH_TO_FZF}"