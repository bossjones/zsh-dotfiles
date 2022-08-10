#!/usr/bin/env zsh

if [[ "$OSTYPE" == linux* ]]
then
    fpath+="$HOME/.zsh/completions"
fi
