# NOTE: I modified this after seeing how he treats certain conditionals
# https://github.com/mcornella/dotfiles/blob/main/zshenv

test -d "$HOME/.cargo/bin" && {
  export PATH=$HOME/.cargo/bin:$PATH
}