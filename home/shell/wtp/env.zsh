WTP_BIN="$(which wtp 2>/dev/null)"

if [ -x "$WTP_BIN" ]; then
    eval "$(wtp shell-init zsh)"
fi
