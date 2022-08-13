# SOURCE: https://github.com/felipecrs/dotfiles/blob/01c9b73a26de9605d47e525d667ab5ac8e7325ad/home/dot_zshrc
# https://github.com/romkatv/powerlevel10k#how-do-i-initialize-direnv-when-using-instant-prompt
if (( ${+commands[direnv]} )); then
    # emulate zsh -c "$(direnv export zsh)"
    eval "$(direnv hook zsh)"
    # NOTE: if this doesn't work use: eval "$(direnv hook zsh)"
fi