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
elif [[ "$OSTYPE" == linux* ]]
then
    _MY_PATH_TO_FZF_COMPLETION=$HOME/.fzf/shell/completion.zsh
fi

# FIXME: temporarily commenting this out. might need to write completion file to disk
# [[ $- == *i* ]] && source "${_MY_PATH_TO_FZF_COMPLETION}" 2> /dev/null
