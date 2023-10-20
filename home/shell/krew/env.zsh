test -d "${KREW_ROOT:-$HOME/.krew}/bin" && {
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
}
