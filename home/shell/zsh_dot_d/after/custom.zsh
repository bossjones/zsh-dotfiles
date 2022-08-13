cp_mp4() {
    rm -fv cp.txt
    touch cp.txt
    mkdir reactions_copy || true
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo cp -av "${filename}" reactions_copy/; done >> cp.txt
    bash -x cp.txt
}

# SOURCE: https://justin.abrah.ms/dotfiles/zsh.html
# Mac Helpers
alias show_hidden="defaults write com.apple.Finder AppleShowAllFiles YES && killall Finder"
alias hide_hidden="defaults write com.apple.Finder AppleShowAllFiles NO && killall Finder"
alias clr='clear;echo "Currently logged in on $(tty), as $(whoami) in directory $(pwd)."'
alias pypath='python -c "import sys; print sys.path" | tr "," "\n" | grep -v "egg"'

# https://justin.abrah.ms/dotfiles/zsh.html
extract_file () {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)        tar xjf $1        ;;
            *.tar.gz)         tar xzf $1        ;;
            *.bz2)            bunzip2 $1        ;;
            *.rar)            unrar x $1        ;;
            *.gz)             gunzip $1         ;;
            *.tar)            tar xf $1         ;;
            *.tar.xz)         tar xf $1         ;;
            *.tbz2)           tar xjf $1        ;;
            *.tgz)            tar xzf $1        ;;
            *.zip)            unzip $1          ;;
            *.Z)              uncompress $1     ;;
            *.7z)             7zr e $1          ;;
            *)                echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# https://justin.abrah.ms/dotfiles/zsh.html
dls () {
    # directory LS
    echo `ls -l | grep "^d" | awk '{ print $9 }' | tr -d "/"`
}
dgrep() {
    # A recursive, case-insensitive grep that excludes binary files
    grep -iR "$@" * | grep -v "Binary"
}
dfgrep() {
    # A recursive, case-insensitive grep that excludes binary files
    # and returns only unique filenames
    grep -iR "$@" * | grep -v "Binary" | sed 's/:/ /g' | awk '{ print $1 }' | sort | uniq
}
# psgrep() {
#     if [ ! -z $1 ] ; then
#         echo "Grepping for processes matching $1..."
#         ps aux | grep $1 | grep -v grep
#     else
#         echo "!! Need name to grep for"
#     fi
# }

exip () {
    # gather external ip address
    echo -n "Current External IP: "
    curl -s -m 5 http://myip.dk | grep "ha4" | sed -e 's/.*ha4">//g' -e 's/<\/span>.*//g'
}

# ips () {
#     # determine local IP address
#     ifconfig | grep "inet " | awk '{ print $2 }'
# }

# https://stackoverflow.com/questions/6918057/shell-list-directories-ordered-by-file-count-including-in-subdirectories
# usage: countFiles Home
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




sort_by_num_files () {

    find . -xdev -type f | cut -d "/" -f 2 | sort | uniq -c | sort -n

}


cd_to_cloud () {
    cd '/Volumes/Macintosh HD/Users/malcolm/Library/Mobile Documents/com~apple~CloudDocs/'
}

alias cd_cloud=cd_to_cloud

cd_to_to_schedule_on_meme_account() {
    pyenv activate ffmpeg-tools3 || true
    cd ~/Downloads/to_schedule_on_meme_account
}

cd_to_albums() {
    pyenv activate ffmpeg-tools3 || true
    cd ~/Downloads/to_schedule_on_meme_account/albums
}

cd_to_waiting_on_audio() {
    pyenv activate ffmpeg-tools3 || true
    cd ~/Downloads/to_schedule_on_meme_account/waiting_on_audio

}

cd_to_meme_show_staging_area() {
    pyenv activate ffmpeg-tools3 || true
    cd '/Volumes/Macintosh HD/Users/malcolm/Movies/Media/meme_show_staging_area'

}

cd_to_meme_show_archive() {
    pyenv activate ffmpeg-tools3 || true
    cd '/Volumes/Macintosh HD/Users/malcolm/Movies/Media/meme show archive'

}

story_to_square_post() {
    pyenv activate ffmpeg-tools3 || true
    ffmpeg-tools -c batch-crop-story,batch-eq-mp4,batch-loop -f "$(PWD)" -r
}

cd_to_to_schedule_on_meme_account_staging() {
    pyenv activate ffmpeg-tools3 || true
    cd ~/Downloads/to_schedule_on_meme_account/staging
}


mkdir_date(){
    mkdir -p $(date +%Y%m%d)/{RAW,staging,normalized,cropped,square,split,more,memelords,titlescreen,tiktoks,story,stories,opener,saved,hunnies,tiktoks} || true
    cd $(date +%Y%m%d)
    pwd
}


####################################

cd_to_to_schedule_on_meme_account_today() {
    pyenv activate ffmpeg-tools3 || true
    cd ~/Downloads/to_schedule_on_meme_account/$(date +%Y%m%d)
    pwd
}

cd_to_albums_today() {
    pyenv activate ffmpeg-tools3 || true
    cd ~/Downloads/to_schedule_on_meme_account/albums/$(date +%Y%m%d)
    cd $(date +%Y%m%d) || mkdir_date
}



cd_to_meme_show_staging_area_today() {
    pyenv activate ffmpeg-tools3 || true
    cd '/Volumes/Macintosh HD/Users/malcolm/Movies/Media/meme_show_staging_area'
    cd $(date +%Y%m%d) || mkdir_date
}

cd_to_meme_show_archive_today() {
    pyenv activate ffmpeg-tools3 || true
    cd '/Volumes/Macintosh HD/Users/malcolm/Movies/Media/meme show archive'
    cd $(date +%Y%m%d) || mkdir_date

}

story_to_square_post_today() {
    pyenv activate ffmpeg-tools3 || true
    ffmpeg-tools -c prepare-from-story -f "$(PWD)" -r
}

cd_to_to_schedule_on_meme_account_staging_today() {
    pyenv activate ffmpeg-tools3 || true
    cd ~/Downloads/to_schedule_on_meme_account/staging
    cd $(date +%Y%m%d) || mkdir_date
}

# SOURCE: https://github.com/zaklaus/dotfiles/blob/1e957bd3c43ca30d8a274940a54aa86d9e15a89a/.zshrc
alias cn='clear; neofetch'			    # cn:	    Clear and display neofetch
mcd () { mkdir -p "$1" && cd "$1"; }        # mcd:          Makes new Dir and jumps inside
# SOURCE: https://github.com/lazmond3/dotfiles-public-mac/blob/81fd93f99582d71206243c16095aecaf456d2c5e/config/aliases.bash
alias killf="kill \$(ps aux | fzf -m | awk '{print \$2}')"


alias mkdir_cd="mcd"

prepare_story() {
    pyenv activate ffmpeg-tools3 || true
    ffmpeg-tools -c prepare-from-story -f "$(PWD)" -r
}

prepare_square() {
    pyenv activate ffmpeg-tools3 || true
    ffmpeg-tools -c prepare-from-square -f "$(PWD)" -r
}

dl_download() {
    pyenv activate ffmpeg-tools3 || true
    ffmpeg-tools -c gallery-dl -f "$(PWD)/download.txt" -r --metadata
}

dl_story() {
    pyenv activate ffmpeg-tools3 || true
    ffmpeg-tools -c dl-story --user "${1}"
}

dl_all() {
    pyenv activate ffmpeg-tools3 || true
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
