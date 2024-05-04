RYE_BIN="$(which rye)"

# completion
if [ -x "$RYE_BIN" ]; then
    eval "$(rye self completion -s zsh)"
fi
