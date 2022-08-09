#!/usr/bin/env zsh

if [[ "$OSTYPE" == darwin* ]]
then
    _ARCH=$(uname -m)
    if [[ "${_ARCH}" = "arm64" ]]
    then
        _MY_PATH_TO_FZF_COMPLETION=/opt/homebrew/opt/fzf/shell/completion.zsh
    else
        _MY_PATH_TO_FZF_COMPLETION=/usr/local/opt/fzf/shell/completion.zsh
    fi
    
    _MY_PATH_TO_FZF_COMPLETION=$HOME/.fzf/shell/completion.zsh
fi

[[ $- == *i* ]] && source "${_MY_PATH_TO_FZF_COMPLETION}" 2> /dev/null
