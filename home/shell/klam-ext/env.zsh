KLAMEXT_BIN="$(which klam-ext)"

if [ -x "$KLAMEXT_BIN" ]; then
    if command -v klam-ext &>/dev/null; then
        eval "$(env klam-ext zsh-integration)"
    fi
fi
