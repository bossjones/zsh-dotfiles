if [[ "$OSTYPE" == linux* ]]
then
    export ASDF_DIR="${HOME}/.asdf"
    export ASDF_COMPLETIONS="$ASDF_DIR/completions"
    fpath=(${ASDF_DIR}/completions $fpath)
fi

# ------------------

OS="`uname`"
case $OS in
  'Linux')
    OS='Linux'
    ;;
  'FreeBSD')
    OS='FreeBSD'
    ;;
  'WindowsNT')
    OS='Windows'
    ;;
  'Darwin')
    OS='Mac'
    ;;
  'SunOS')
    OS='Solaris'
    ;;
  *) ;;
esac

if [ "$OS" = 'Mac' ]
then
    export ASDF_DIR="${HOME}/.asdf"
    export ASDF_COMPLETIONS="$ASDF_DIR/completions"
    fpath=(${ASDF_DIR}/completions $fpath)
fi
