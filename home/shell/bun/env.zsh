# Bun
export BUN_INSTALL="$HOME/.bun"

if [ -d "$BUN_INSTALL" ]; then
    export PATH="$BUN_INSTALL/bin:$PATH"

    # bun completions
    [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
fi
