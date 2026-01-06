export CHEAT_CONFIG_PATH="~/.config/cheat/conf.yml"


cheat_update_personal() {
    pushd ~/.config/cheat/cheatsheets/personal
    git pull --rebase || true
    popd
    cheat -l
}

export CHEAT_USE_FZF=true
