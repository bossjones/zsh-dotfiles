if [ "${ZSH_DOTFILES_VERSION_MANAGER:-}" = "mise" ] && command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi
