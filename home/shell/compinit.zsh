#!/usr/bin/env zsh

# ----------------------------------------------------------------------
# SOURCE: https://github.com/z0rc/dotfiles/blob/7940585d409cfe705af817ee7af8bcd4ea3b25da/zsh/rc.d/14_completion.zsh#L17
# ----------------------------------------------------------------------
# # Init completions, but regenerate compdump only once a day.
# # The globbing is a little complicated here:
# # - '#q' is an explicit glob qualifier that makes globbing work within zsh's [[ ]] construct.
# # - 'N' makes the glob pattern evaluate to nothing when it doesn't match (rather than throw a globbing error)
# # - '.' matches "regular files"
# # - 'mh+20' matches files (or directories or whatever) that are older than 20 hours.
# autoload -Uz compinit
# if [[ -n "${XDG_CACHE_HOME}/zsh/compdump"(#qN.mh+20) ]]; then
#     compinit -i -u -d "${XDG_CACHE_HOME}/zsh/compdump"
#     # zrecompile fresh compdump in background
#     {
#         autoload -Uz zrecompile
#         zrecompile -pq "${XDG_CACHE_HOME}/zsh/compdump"
#     } &!
# else
#     compinit -i -u -C -d "${XDG_CACHE_HOME}/zsh/compdump"
# fi

# # Enable bash completions too
# autoload -Uz bashcompinit
# bashcompinit
# ----------------------------------------------------------------------

# Load all stock functions (from $fpath files) called below.
autoload -U compaudit compinit

# Figure out the SHORT hostname
if [[ "$OSTYPE" = darwin* ]]; then
  # macOS's $HOST changes with dhcp, etc. Use ComputerName if possible.
  SHORT_HOST=$(scutil --get ComputerName 2>/dev/null) || SHORT_HOST=${HOST/.*/}
else
  SHORT_HOST=${HOST/.*/}
fi

# Save the location of the current completion dump file.
ZSH_COMPDUMP="${ZDOTDIR:-${HOME}}/.zcompdump-${SHORT_HOST}-${ZSH_VERSION}"

# Construct zcompdump metadata, we will rebuild the Zsh compdump if either
# this file changes or the fpath changes.
zcompdump_revision="#revision: $(sha1sum $0:A)"
zcompdump_fpath="#fpath: $fpath"

# Delete the zcompdump file if zcompdump metadata changed
if ! command grep -q -Fx "$zcompdump_revision" "$ZSH_COMPDUMP" 2>/dev/null \
   || ! command grep -q -Fx "$zcompdump_fpath" "$ZSH_COMPDUMP" 2>/dev/null; then
  command rm -f "$ZSH_COMPDUMP"
  zcompdump_refresh=1
fi

# If the user wants it, load from all found directories
compinit -u -C -d "${ZSH_COMPDUMP}"

# Append zcompdump metadata if missing
if (( $zcompdump_refresh )); then
  echo "\n$zcompdump_revision\n$zcompdump_fpath" >>! "$ZSH_COMPDUMP"
fi

unset zcompdump_revision zcompdump_fpath zcompdump_refresh
