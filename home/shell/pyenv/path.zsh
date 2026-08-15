
OS="`uname`"
case $OS in
  'Linux')
    OS='Linux'
    ;;
  'FreeBSD')
    OS='FreeBSD'
    ;;
  'WindowsNT')
    OS='Windows'
    ;;
  'Darwin')
    OS='Mac'
    ;;
  'SunOS')
    OS='Solaris'
    ;;
  *) ;;
esac

if [ "$OS" = 'Mac' ]
then
    _ARCH=$(uname -m)
    if [ "${_ARCH}" = "arm64" ]
    then
        _MY_OPT_HOMEBREW=/opt/homebrew
    else
        _MY_OPT_HOMEBREW=/usr/local
    fi
    export OPT_HOMEBREW="${_MY_OPT_HOMEBREW}"

    # HOMEBREW_PREFIX is only exported by `brew shellenv` (via .zprofile), so it is
    # empty in ssh shells. Fall back to the prefix derived from the arch above.
    _MY_PYENV_PREFIX="${HOMEBREW_PREFIX:-${_MY_OPT_HOMEBREW}}"

    if [ -s "${_MY_PYENV_PREFIX}/opt/pyenv/libexec/pyenv" ]
    then
        # [SOLVED] Getting "Failed to activate virtualenv" when using with pyenv 2.0.0-rc1-2-gac4de222 (cloned on 2021-05-22)
        # SOURCE: https://github.com/pyenv/pyenv-virtualenv/issues/387
        eval "$(${_MY_PYENV_PREFIX}/opt/pyenv/libexec/pyenv init --path)"
        eval "$(${_MY_PYENV_PREFIX}/opt/pyenv/libexec/pyenv init -)"
        eval "$(${_MY_PYENV_PREFIX}/opt/pyenv/libexec/pyenv virtualenv-init -)"
        fpath=(${_MY_PYENV_PREFIX}/opt/pyenv/completions $fpath)
        # ${_MY_PYENV_PREFIX}/opt/pyenv/libexec/pyenv virtualenvwrapper_lazy

    elif [ -s "${HOME}/.pyenv/bin/pyenv" ]
    then
        export PYENV_ROOT="${HOME}/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$($HOME/.pyenv/bin/pyenv init --path)"
        eval "$($HOME/.pyenv/bin/pyenv init -)"
        # $HOME/.pyenv/bin/pyenv virtualenvwrapper_lazy
    fi

else
    if [ -d "${HOME}/.pyenv" ]
    then
        export PYENV_ROOT="${HOME}/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$($HOME/.pyenv/bin/pyenv init --path)"
        eval "$($HOME/.pyenv/bin/pyenv init -)"
        # $HOME/.pyenv/bin/pyenv virtualenvwrapper_lazy
    fi
fi
