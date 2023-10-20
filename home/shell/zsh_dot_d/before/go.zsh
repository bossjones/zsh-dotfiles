# if [ -d "/usr/local/go/bin" ]; then
#   export PATH=/usr/local/go/bin:$PATH
# fi

# NOTE: I modified this after seeing how he treats certain conditionals
# https://github.com/mcornella/dotfiles/blob/main/zshenv

test -d "/opt/homebrew/opt/go" && {
  export PATH="/opt/homebrew/opt/go/bin:${PATH}"
  export PATH=$GOPATH/bin:$PATH
  export PATH="$HOME/go/bin:$PATH"
  alias cdgo='CDPATH=.:$GOPATH/src/github.com:$GOPATH/src/golang.org:$GOPATH/src'
}

test -d "$HOME/.goenv" && {
  export GOENV_ROOT="$HOME/.goenv"
  export PATH="$GOENV_ROOT/bin:$PATH"
  eval "$(goenv init -)"
  export PATH="$GOROOT/bin:$PATH"
  export PATH="$PATH:$GOPATH/bin"
}
