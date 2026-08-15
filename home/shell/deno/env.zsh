# Deno
export DENO_INSTALL="$HOME/.deno"

if [ -d "$DENO_INSTALL" ]; then
    export PATH="$DENO_INSTALL/bin:$PATH"
    . "$DENO_INSTALL/env"
fi
