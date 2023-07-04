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


# # HISTFILE - Refers to the path/location of the history file
# export HISTFILE="$HOME/.zsh_history"

# # 2. Increase history size
# # In bash, Setting the HISTFILESIZE and HISTSIZE variables to an empty string makes the bash history size unlimited. However, it's not possible to set the history to an unlimited size in zsh(theoretically, at least). From an zsh mailing list, it appears the max history size can be LONG_MAX from limits.h header file. That has a (really huge) value of 9223372036854775807, which should be enough to store trillions of commands (a limit we'll probably never hit). This number can be hard to remember - We can just set this to a billion, and forget it.
# export HISTFILESIZE=1000000000
# # HISTSIZE - Refers to the number of commands that are loaded into memory from the history file
# export HISTSIZE=1000000000

# export SAVEHIST=$HISTSIZE

# # set some history options
# # Appends new history entries to the history file
# setopt append_history
# # Records timestamps and durations in history
# setopt extended_history
# # Expire older duplicate history entries first
# setopt hist_expire_dups_first
# # Ignores all but the most recent of duplicate history entries
# setopt hist_ignore_all_dups
# # Ignores consecutive duplicate history entries
# setopt hist_ignore_dups
# # Ignores commands starting with spaces in history
# setopt hist_ignore_space
# # Reduces multiple consecutive blanks to a single blank in history
# setopt hist_reduce_blanks
# # Does not save duplicate history entries
# setopt hist_save_no_dups
# # Shows the command with history expansion before running it
# setopt hist_verify
# # Increments history file name to avoid overwriting
# setopt INC_APPEND_HISTORY
# export HISTTIMEFORMAT="[%F %T] "
# # Disables the beep sound when accessing non-existent history entries
# unsetopt HIST_BEEP

# # Share your history across all your terminal windows
# setopt share_history
# #setopt noclobber

# # Larger bash history (allow 32³ entries; default is 500)



# # SAVEHIST - Refers to the number of commands that are stored in the zsh history file
# # SAVEHIST=100000
