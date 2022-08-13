if [[ "$OSTYPE" == darwin* ]]
then
    updatedb () {
        set -x
        alias locate=glocate
        [[ -f "$HOME/locatedb" ]] && export LOCATE_PATH="$HOME/locatedb"
        gupdatedb --prunepaths=/Volumes --output=$HOME/locatedb
        set +x
    }
fi
