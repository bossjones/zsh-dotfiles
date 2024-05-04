LVIM_BIN="$(which lvim)"

if [ -x "$LVIM_BIN" ]; then
    export VISUAL=vim
    export EDITOR="$VISUAL"
    export GIT_EDITOR="$VISUAL"
else
    export VISUAL=lvim
    export EDITOR="$VISUAL"
    export GIT_EDITOR="$VISUAL"
fi
