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

# python better exceptions
export BETTER_EXCEPTIONS=1

export KUBECONFIG="${HOME}/dev/adobe-platform/k8s-kubeconfig/kubeconfig.yaml"
export SHELDON_CONFIG_DIR="$HOME/.sheldon"
export SHELDON_DATA_DIR="$HOME/.sheldon"

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
else
    SHELL="/usr/bin/zsh"
fi

export SHELL
