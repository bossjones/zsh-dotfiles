if [[ "$OSTYPE" == linux* ]]
then
    export ASDF_DIR="${HOME}/.asdf"
    export ASDF_COMPLETIONS="$ASDF_DIR/completions"
    fpath=(${ASDF_DIR}/completions $fpath)
fi
