#!/usr/bin/env zsh
# fzf-tab configuration and runtime toggle helpers.
#
# Loaded only when the chezmoi `fzf_tab` feature flag is on (see plugins.toml.tmpl).
# Deferred, and registered immediately BEFORE compinit so that `:completion:*` styles
# are in place first, per fzf-tab's README.
#
# Toggle layers (cheapest first):
#   toggle-fzf-tab            plugin built-in, current shell only
#   fzf-tab-off / fzf-tab-on  sentinel-backed, persists across shells, no chezmoi
#   chezmoi flag              edit data.fzf_tab in ~/.config/chezmoi/chezmoi.yaml + apply

_zsh_dotfiles_fzf_tab_sentinel="${XDG_CONFIG_HOME:-$HOME/.config}/zsh-dotfiles/fzf-tab-disabled"

# All styles live in a function so fzf-tab-on can re-apply them after fzf-tab-off
# deleted them.
_zsh_dotfiles_fzf_tab_styles() {
  # --- :completion:* prerequisites ----------------------------------------------
  # Group headers require a descriptions format. fzf-tab strips escape sequences
  # here, so keep it plain (no %F{red}).
  zstyle ':completion:*:descriptions' format '[%d]'

  # fzf-tab supersedes zsh's own menu; `menu no` is what lets it capture the
  # unambiguous prefix (see -ftb-complete's compstate[unambiguous] handling).
  zstyle ':completion:*' menu no

  # LS_COLORS is populated by zsh-dircolors-solarized in the defer-more phase, long
  # after this file is sourced -- so evaluate lazily with `zstyle -e`, not `zstyle`.
  zstyle -e ':completion:*' list-colors 'reply=("${(s.:.)LS_COLORS}")'

  # --- :fzf-tab:* ----------------------------------------------------------------
  zstyle ':fzf-tab:*' show-group full
  zstyle ':fzf-tab:*' single-group color header
  zstyle ':fzf-tab:*' continuous-trigger '/'
  zstyle ':fzf-tab:*' switch-group F1 F2
  zstyle ':fzf-tab:*' fzf-min-height 15
  zstyle ':fzf-tab:*' fzf-pad 4

  # Directory previews. eza when present, BSD/GNU-portable ls otherwise.
  if command -v eza >/dev/null 2>&1; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  else
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 $realpath'
  fi

  # tmux popup rendering requires tmux >= 3.2. ftb-tmux-popup already degrades to
  # plain fzf when $TMUX_PANE is unset, so gate on version only, not "am I inside
  # tmux".
  local ftb_tmux_ver
  if command -v tmux >/dev/null 2>&1; then
    ftb_tmux_ver=$(tmux -V 2>/dev/null)
    ftb_tmux_ver=${ftb_tmux_ver#tmux }        # "tmux 3.5a" -> "3.5a"
    ftb_tmux_ver=${ftb_tmux_ver%%[^0-9.]*}    # "3.5a"      -> "3.5"
    autoload -Uz is-at-least
    if [[ -n $ftb_tmux_ver ]] && is-at-least 3.2 $ftb_tmux_ver; then
      zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
      zstyle ':fzf-tab:*' popup-min-size 80 12
      zstyle ':fzf-tab:*' popup-pad 0 0
    fi
  fi
}

# Persistent off-switch: disables the current shell now and, via the sentinel,
# every future shell (defer-if-fzf in plugins.toml skips sourcing fzf-tab).
fzf-tab-off() {
  mkdir -p "${_zsh_dotfiles_fzf_tab_sentinel:h}"
  touch "$_zsh_dotfiles_fzf_tab_sentinel"
  (( $+functions[disable-fzf-tab] )) && disable-fzf-tab
  # Revert the styles this file set, so stock compsys behaves exactly like the
  # flag-off render. (fzf-tab's own disable-fzf-tab already restores list-grouped.)
  zstyle -d ':completion:*:descriptions' format
  zstyle -d ':completion:*' menu
  zstyle -d ':completion:*' list-colors
  print "fzf-tab disabled (persists across shells; run fzf-tab-on to re-enable)"
}

fzf-tab-on() {
  rm -f "$_zsh_dotfiles_fzf_tab_sentinel"
  # enable-fzf-tab only exists if the plugin was sourced; when the sentinel was
  # present at startup, defer-if-fzf skipped it entirely.
  if (( $+functions[enable-fzf-tab] )); then
    _zsh_dotfiles_fzf_tab_styles
    enable-fzf-tab
    print "fzf-tab enabled"
  else
    print "fzf-tab will load in new shells (run: exec zsh)"
  fi
}

# The helpers above are defined unconditionally so a disabled shell can still run
# fzf-tab-on. Styles apply only when the toggle is not off.
[[ -f "$_zsh_dotfiles_fzf_tab_sentinel" ]] && return 0
_zsh_dotfiles_fzf_tab_styles
