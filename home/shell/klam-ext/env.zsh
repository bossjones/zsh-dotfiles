# NOTE: I modified this after seeing how he treats certain conditionals
# https://github.com/mcornella/dotfiles/blob/main/zshenv
OS_NAME="$(/usr/bin/uname -s)"
UNAME_MACHINE="$(/usr/bin/uname -m)"
if [ "$OS_NAME" = "Darwin" ]; then

    KLAMEXT_BIN="$(which klam-ext)"

    if [ -x "$KLAMEXT_BIN" ]; then
        if command -v klam-ext &>/dev/null; then
            eval "$(env klam-ext zsh-integration)"
        fi
    fi
fi
