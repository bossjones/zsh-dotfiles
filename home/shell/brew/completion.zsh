#!/usr/bin/env zsh

if [[ "$OSTYPE" == darwin* ]]
then
    fpath+=$HOMEBREW_PREFIX/share/zsh/site-functions
fi