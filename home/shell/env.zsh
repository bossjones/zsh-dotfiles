#!/usr/bin/env zsh

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Less recursive by default
export LESS=-eFR

# You Should Use
# Plugin: MichaelAquilina/zsh-you-should-use
export YSU_MODE=ALL

export CODE_WORKSPACE=$HOME/dev

export EDITOR=nvim
export VEDITOR=code

# https://github.com/x-motemen/ghq#environment-variables
export GHQ_ROOT=$CODE_WORKSPACE


## On centos we need to custom compile A LOT of stuff, so tell the shell to use it all
{{if (eq .chezmoi.os "linux") -}}
{{- if (eq .chezmoi.osRelease.name "CentOS Linux") -}}
export CC=$HOME/.gcc/10.2.0/bin/gcc
export CXX=$HOME/.gcc/10.2.0/bin/g++
export FC=$HOME/.gcc/10.2.0/bin/gfortran
export LD_LIBRARY_PATH=$HOME/.gcc/10.2.0/lib64
. "$HOME/.cargo/env"
{{ end -}}
{{ end -}}


export GOPATH="$HOME/go"
export TERM="xterm-256color"
export EDITOR="vim"

if [[ "$OSTYPE" == darwin* ]]
then
    _ARCH=$(uname -m)
    if [[ "${_ARCH}" = "arm64" ]]
    then
        SHELL="/opt/homebrew/bin/zsh"
    else
        SHELL="/usr/local/bin/zsh"
    fi

    SHELL="/usr/bin/zsh"
fi

export SHELL
