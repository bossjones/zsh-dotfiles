FNM_BIN="$(which fnm)"

if [ -x "$FNM_BIN" ]; then
    eval "$($FNM_BIN env --use-on-cd)"
fi
