if [[ "$OSTYPE" == darwin* ]]
then

  get_man_exorts() {
    for i in /usr/local/Cellar/*/*/share/man; do
      echo 'export MANPATH="'$i':$MANPATH"'
    done
    for i in /usr/local/Cellar/*/*/libexec/gnuman; do
      echo 'export MANPATH="'$i':$MANPATH"'
    done
  }

fi