#!/usr/bin/env zsh

if [[ "$OSTYPE" == darwin* ]]
then

    UNAME_MACHINE="$(/usr/bin/uname -m)"
    if [ "$UNAME_MACHINE" = "arm64" ]
    then
      HOMEBREW_PREFIX="/opt/homebrew"
      HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}"
    else
      HOMEBREW_PREFIX="/usr/local"
      HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
    fi

    fpath+=$HOMEBREW_PREFIX/share/zsh/site-functions
fi
