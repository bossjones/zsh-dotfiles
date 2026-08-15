# SOURCE: https://unix.stackexchange.com/a/442424/44712
tmux-copy-screen() {
    tmux capture-pane -pS -1000000 > file.out
}
