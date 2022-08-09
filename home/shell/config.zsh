#!/usr/bin/env zsh

# Keep 10,000,000 lines of history within the shell and save it to ~/.zsh_history:
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000000
SAVEHIST=10000000

# Use vi keybindings
set -o vi
bindkey -v

# Docs https://zsh.sourceforge.io/Doc/Release/Options.html
setopt NO_BEEP
# Don't record an entry that was just recorded again.
setopt HIST_IGNORE_DUPS
# Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_ALL_DUPS
# Expire duplicate entries first when trimming history.
setopt HIST_EXPIRE_DUPS_FIRST
# Don't record an entry starting with a space.
setopt HIST_IGNORE_SPACE
# Remove superfluous blanks before recording entry.
setopt HIST_REDUCE_BLANKS
# Don't execute immediately upon history expansion.
setopt HIST_VERIFY
# Treat the '!' character specially during expansion.
setopt BANG_HIST
# Write the history file in the ":start:elapsed;command" format.
setopt EXTENDED_HISTORY
# Write to the history file immediately, not when the shell exits.
setopt INC_APPEND_HISTORY
# Share history between all sessions.
setopt NO_SHARE_HISTORY
# Do not display a line previously found.
setopt HIST_FIND_NO_DUPS
# Don't write duplicate entries in the history file.
setopt HIST_SAVE_NO_DUPS

# Move cursor to end of word if a full completion is inserted.
setopt ALWAYS_TO_END
# Case-insensitive globbing (used in pathname expansion)
unsetopt CASE_GLOB
# Don't beep on ambiguous completions.
setopt NO_LIST_BEEP

# Case-insesitive matching or partial word matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' '+r:|?=**'

# TODO organize aliases
# alias brew='sudo -Hu ops -i brew'
# alias c=chezmoi
# alias e="$EDITOR"
