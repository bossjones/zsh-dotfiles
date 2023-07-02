#!/usr/bin/env zsh

if [[ "$OSTYPE" == linux* ]]
then
    fpath+="$HOME/.zsh/completions"
fi

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
    fpath+="$HOME/.zsh/completions"
    fpath+="$HOME/.zsh/completion"
fi
