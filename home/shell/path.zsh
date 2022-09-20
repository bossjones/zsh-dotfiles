#!/usr/bin/env zsh

# path+=$HOME/.local/bin


# The $path array variable is tied to the $PATH scalar (string) variable. Any modification on one is reflected in the other.
# path=(
#     $HOME/bin
#     $HOME/.bin
#     $HOME/.local/bin
#     $HOME/.fnm
#     /usr/local/sbin
#     /usr/local/bin
#     /usr/sbin
#     /usr/bin
#     /sbin
#     /bin
#     $path
# )

path+=($HOME/bin)
path+=($HOME/.bin)
path+=($HOME/.local/bin)
# path+=($HOME/.fnm)
path+=(/usr/local/sbin)
path+=(/usr/local/bin)
path+=(/usr/sbin)
path+=(/usr/bin)
path+=(/sbin)
path+=(/bin)

# [[ -d $ZDOTDIR/bin ]] && path+=($ZDOTDIR/bin)
