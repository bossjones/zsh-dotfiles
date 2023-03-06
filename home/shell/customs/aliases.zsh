# ---------------------------------------------------------
# chezmoi managed - aliases.zsh
# ---------------------------------------------------------
cp_mp4() {
    rm -fv cp.txt
    touch cp.txt
    mkdir reactions_copy || true
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo cp -av "${filename}" reactions_copy/; done >> cp.txt
    bash -x cp.txt
}

# https://stackoverflow.com/questions/6918057/shell-list-directories-ordered-by-file-count-including-in-subdirectories
countFiles () {
    # call the recursive function, throw away stdout and send stderr to stdout
    # then sort numerically
    countFiles_rec "$1" 2>&1 >/dev/null | sort -nr
}

countFiles_rec () {
    local -i nfiles
    dir="$1"

    # count the number of files in this directory only
    nfiles=$(find "$dir" -mindepth 1 -maxdepth 1 -type f -print | wc -l)

    # loop over the subdirectories of this directory
    while IFS= read -r subdir; do

        # invoke the recursive function for each one
        # save the output in the positional parameters
        set -- $(countFiles_rec "$subdir")

        # accumulate the number of files found under the subdirectory
        (( nfiles += $1 ))

    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print)

    # print the number of files here, to both stdout and stderr
    printf "%d %s\n" $nfiles "$dir" | tee /dev/stderr
}


# countFiles Home

sort_by_num_files () {

    find . -xdev -type f | cut -d "/" -f 2 | sort | uniq -c | sort -n

}

mkdir_date(){
    mkdir -p $(date +%Y%m%d)/{RAW,staging,normalized,cropped,square,split,more,memelords,titlescreen,tiktoks,story,stories,opener,saved,hunnies,tiktoks} || true
    cd $(date +%Y%m%d)
    pwd
}

# SOURCE: https://github.com/zaklaus/dotfiles/blob/1e957bd3c43ca30d8a274940a54aa86d9e15a89a/.zshrc
mcd () { mkdir -p "$1" && cd "$1"; }        # mcd:          Makes new Dir and jumps inside
# SOURCE: https://github.com/lazmond3/dotfiles-public-mac/blob/81fd93f99582d71206243c16095aecaf456d2c5e/config/aliases.bash
alias killf="kill \$(ps aux | fzf -m | awk '{print \$2}')"
alias mkdir_cd="mcd"

prepare_story() {
    pyenv activate ffmpeg-tools399 || true
    # gallery-dl --clear-cache instagram
    ffmpeg-tools -c prepare-from-story -f "$(PWD)" -r
}

prepare_square() {
    pyenv activate ffmpeg-tools399 || true
    # gallery-dl --clear-cache instagram
    ffmpeg-tools -c prepare-from-square -f "$(PWD)" -r
}

dl_download() {
    pyenv activate ffmpeg-tools399 || true
    # gallery-dl --clear-cache instagram
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --metadata
}

dl_story() {
    pyenv activate ffmpeg-tools399 || true
    # gallery-dl --clear-cache instagram
    ffmpeg-tools -c dl-story --user "${1}"
}

dl_all() {
    pyenv activate ffmpeg-tools399 || true
    # gallery-dl --clear-cache instagram
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '0-100' --metadata
    sleep $((1 + $RANDOM % 10))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '101-200' --metadata
    sleep $((1 + $RANDOM % 10))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '201-300' --metadata
    sleep $((1 + $RANDOM % 10))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '301-400' --metadata
    sleep $((1 + $RANDOM % 10))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '401-500' --metadata
    sleep $((1 + $RANDOM % 10))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '501-600' --metadata
    sleep $((1 + $RANDOM % 10))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '601-700' --metadata
    sleep $((1 + $RANDOM % 10))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '701-800' --metadata
    echo -e " [run] countFiles $(PWD)\n"
    countFiles "$(PWD)"
}

print_sleep() {
    _SLEEP="${1}"
    echo " [sleep] ${_SLEEP}s"
    sleep "${_SLEEP}"
}

dl_all_hard_sleeps() {
    pyenv activate ffmpeg-tools399 || true
    gallery-dl --clear-cache instagram
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '0-100' --metadata
    _BASE="$((30 * 1))"
    print_sleep ${_BASE}
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '101-200' --metadata
    _BASE="$((${_BASE} * 2))"
    print_sleep $((${_BASE}**2))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '201-300' --metadata
    _BASE="$((${_BASE} * 2))"
    print_sleep $((${_BASE}**2))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '301-400' --metadata
    _BASE="$((${_BASE} * 2))"
    print_sleep $((${_BASE}**2))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '401-500' --metadata
    _BASE="$((${_BASE} * 2))"
    print_sleep $((${_BASE}**2))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '501-600' --metadata
    _BASE="$((${_BASE} * 2))"
    print_sleep $((${_BASE}**2))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '601-700' --metadata
    _BASE="$((${_BASE} * 2))"
    print_sleep $((${_BASE}**2))
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --range '701-800' --metadata
    echo -e " [run] countFiles $(PWD)\n"
    countFiles "$(PWD)"
}

interactive_meme_categories() {
    pyenv activate ffmpeg-tools399 || true
    gallery-dl --clear-cache instagram
    ffmpeg-tools -c interactive-reaction-videos -f "$(PWD)"
}

ascrape() {
    fname="${1}"
    pyenv activate aioscraper399 || true
    cd ~/dev/bossjones/sandbox/aioscraper
    echo "${fname}" | tee -a scrape.log
    set -x
    python aioscraper/cli.py scrape -- ${fname}
    set +x
}

batch_interactive_reactions() {
    interactive_meme_categories
}

open_ig_hashtag() {
    open-browser.py "https://www.instagram.com/explore/tags/${1}/"
}

split_scenes(){
    pyenv activate cerebro_bot3 || true
    echo '#!/usr/bin/env bash' > redo.sh
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo scenedetect -i "$filename" -o processed/ detect-content split-video; done >> redo.sh
    echo "Script created. cat redo.sh"
    cat redo.sh
    chmod +x redo.sh
    mkdir -p processed/ || true
    ./redo.sh
}

tmux-copy-screen () {
        _zsh_tmux_plugin_run capture-pane -pS -1000000 > file.out
}

ffmpeg_info() {
    ffprobe -v quiet -print_format json -show_format -show_streams -i "${1}" | jq
}

alias imgdupes="docker run --rm -it -v $PWD:/app knjcode/imgdupes"

git-fork-sync() {
    git fetch upstream master && git rebase upstream/master
}

git-fork-sync-main() {
    git fetch upstream main && git rebase upstream/main
}

run_filebrowser() {
    cd ~/Downloads
    echo " [running]  filebrowser -a 0.0.0.0 -r ./farming -p 6060"
    filebrowser -a 0.0.0.0 -r ./farming -p 6060
}

dl-ig-wavy() {
    pyenv activate cerebro-bot399 || true
    gallery-dl --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata --cookies ~/.config/gallery-dl/wavy-cookies-instagram.txt ${1}
}

dl-ig-hlm() {
    pyenv activate cerebro-bot399 || true
    gallery-dl --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata --cookies ~/.config/gallery-dl/hlm-cookies-instagram.txt ${1}
}

alias reload!='exec "$SHELL" -l'

fixprompt() {
    reload!
}
# pi@boss-station ~/.zsh.d/after
# ❯ cat custom_plugins.zsh
# plugins+=(git-extra-commands zsh-256color zsh-peco-history pyenv rbenv fd fzf zsh-syntax-highlighting tmux conda-zsh-completion)

# ---------------------------------------------------------
# chezmoi managed - end.zsh
# ---------------------------------------------------------