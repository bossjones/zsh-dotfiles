# # see `man zshoptions`
# # SOURCE: https://linux.die.net/man/1/zshoptions
# # SOURCE: http://zsh.sourceforge.net/Doc/Release/Options.html
# # Save each command's beginning timestamp (in seconds since the epoch) and the duration (in seconds) to the history file. The format of this prefixed data is:
# # ':<beginning time>:<elapsed seconds>:<command>'.
# setopt EXTENDED_HISTORY

# # If a new command line being added to the history list duplicates an older one, the older command is removed from the list (even if it is not the previous event).
# setopt HIST_IGNORE_ALL_DUPS

# # APPEND_HISTORY <D>
# # If this is set, zsh sessions will append their history list to the history file, rather than replace it. Thus, multiple parallel zsh sessions will all have the new entries from their history lists added to the history file, in the order that they exit. The file will still be periodically re-written to trim it when the number of lines grows 20% beyond the value specified by $SAVEHIST (see also the HIST_SAVE_BY_COPY option).
# # --------------------------------------------------
# # This options works like APPEND_HISTORY except that new history lines are added to the $HISTFILE incrementally (as soon as they are entered), rather than waiting until the shell exits. The file will still be periodically re-written to trim it when the number of lines grows 20% beyond the value specified by $SAVEHIST (see also the HIST_SAVE_BY_COPY option).
# setopt INC_APPEND_HISTORY

# setopt INC_APPEND_HISTORY_TIME
# setopt SHARE_HISTORY

# SOURCE: https://github.com/balakrishnanc/dotfiles/blob/bff74304808b68ffbc571b2d13d3b8077ce65c4e/zsh/zshenv.template
# Remove superfluous blanks from each command line being added
#  to the history list.
setopt HIST_REDUCE_BLANKS

# When writing out the history file, older commands that duplicate newer ones
#  are omitted.
setopt HIST_SAVE_NO_DUPS

# If you find that you want more control over when commands get imported,
#  you may wish to turn SHARE_HISTORY off,
#  INC_APPEND_HISTORY or INC_APPEND_HISTORY_TIME on, and then manually import
#  commands whenever you need them using 'fc -RI'.
unsetopt SHARE_HISTORY

# This option is a variant of INC_APPEND_HISTORY in which, where possible,
#  the history entry is written out to the file after the command is finished,
#  so that the time taken by the command is recorded correctly in the
#  history file in EXTENDED_HISTORY format. This means that the history entry
#  will not be available immediately from other instances of the shell that are
#  using the same history file.
# This option is only useful if INC_APPEND_HISTORY and SHARE_HISTORY are
#  turned off. The three options should be considered mutually exclusive.
setopt INC_APPEND_HISTORY_TIME

# This options works like APPEND_HISTORY except that new history lines are
#  added to the $HISTFILE incrementally (as soon as they are entered),
#  rather than waiting until the shell exits.
unsetopt INC_APPEND_HISTORY
