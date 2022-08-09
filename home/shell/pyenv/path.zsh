
if [[ "$OSTYPE" == darwin* ]]
then
    _ARCH=$(uname -m)
    if [[ "${_ARCH}" = "arm64" ]]
    then
        _MY_OPT_HOMEBREW=/opt/homebrew
        export OPT_HOMEBREW="${_MY_OPT_HOMEBREW}"
        eval "$(${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv init --path)"
        eval "$(${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv init -)"
        fpath=(${HOMEBREW_PREFIX}/opt/pyenv/completions $fpath)
        ${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv virtualenvwrapper_lazy
    else
        _MY_OPT_HOMEBREW=/usr/local
        export OPT_HOMEBREW="${_MY_OPT_HOMEBREW}"
        eval "$(${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv init --path)"
        eval "$(${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv init -)"
        fpath=(${HOMEBREW_PREFIX}/opt/pyenv/completions $fpath)
        ${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv virtualenvwrapper_lazy
    fi

else
    # export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$($HOME/.pyenv/bin/pyenv init --path)"
    eval "$($HOME/.pyenv/bin/pyenv init -)"
    $HOME/.pyenv/bin/pyenv virtualenvwrapper_lazy
fi
