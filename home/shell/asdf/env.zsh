if [[ "$OSTYPE" == linux* ]]
then
    export ASDF_DIR="${HOME}/.asdf"
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
fi
