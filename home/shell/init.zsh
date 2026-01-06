if [[ "$OSTYPE" == linux* ]]; then
    # XDG configuration for linux
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
fi

# Makes path a unique array preventing duplicates
typeset -U path
typeset -U fpath
# typeset -U cdpath
# typeset -U mailpath
