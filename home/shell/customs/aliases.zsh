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
    pyenv activate yt-dlp3 || true
    echo '#!/usr/bin/env bash' > redo.sh
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo scenedetect -i "$filename" -o processed/ detect-content split-video; done >> redo.sh
    echo "Script created. cat redo.sh"
    cat redo.sh
    chmod +x redo.sh
    mkdir -p processed/ || true
    ./redo.sh
}

tmux-copy-screen () {
        # _zsh_tmux_plugin_run capture-pane -pS -1000000 > file.out
        tmux capture-pane -pS -1000000 > file.out
}

ffmpeg_info() {
    ffprobe -v quiet -print_format json -show_format -show_streams -i "${1}" | jq
}

alias imgdupes="docker run --rm -it -v $PWD:/app knjcode/imgdupes"

enable_asdf() {
    . "$HOME"/.asdf/asdf.sh
}

alias imgdupes="docker run -it -v $PWD:/app knjcode/imgdupes"


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
    pyenv activate yt-dlp3 || true
    gallery-dl --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata --cookies ~/.config/gallery-dl/wavy-cookies-instagram.txt ${1}
}

dl-ig-hlm() {
    pyenv activate yt-dlp3 || true
    gallery-dl --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata --cookies ~/.config/gallery-dl/hlm-cookies-instagram.txt ${1}
}

alias reload!='exec "$SHELL" -l'

fixprompt() {
    reload!
}

alias trw="tmux rename-window"

alias dotfiles_provision='chezmoi init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git'
# pi@boss-station ~/.zsh.d/after
# ❯ cat custom_plugins.zsh
# plugins+=(git-extra-commands zsh-256color zsh-peco-history pyenv rbenv fd fzf zsh-syntax-highlighting tmux conda-zsh-completion)

dl(){
    echo "running dl \"${1}\" ..."
    /usr/local/bin/youtube-dl -o "$(uuidgen).%(ext)s" "${1}"
    echo ""
}

dl-best(){
    echo "running dl-best \"${1}\" ..."
    /usr/local/bin/youtube-dl -o "$(uuidgen).%(ext)s" -f $(/usr/local/bin/youtube-dl -o "$(uuidgen).%(ext)s" -F "${1}" | grep best | grep mp4 | head -1 | awk '{print $1}') "${1}"
    echo ""
}

dl-mp3(){
    echo "running dl-mp3 \"${1}\" ..."
    /usr/local/bin/youtube-dl --extract-audio --audio-format mp3 "${1}"
    echo ""
}

youtube-dl-best-until(){
    until dl-best "${1}" &> /dev/null
    do
        echo "running dl-best \"${1}\" ..."
        sleep 1
    done
    echo -e "\nThe mp4 is downloaded."
}



youtube-dl-mp3-orig-name-until(){
    until dl-mp3-orig-name "${1}" &> /dev/null
    do
        echo "running dl-mp3-orig-name \"${1}\" ..."
        sleep $((1 + $RANDOM % 10))
    done
    echo -e "\nThe mp3 is downloaded."
}



# SOURCE: https://github.com/gko/dotfiles/blob/6f63f4a5ffdfbded718bd1eee8723e02ec2a5335/aliases/youtube-dl.sh
youtube-dl-aliases () {
	local YOUTUBE_DL_OPTIONS="--ignore-errors \
		--restrict-filenames \
		--no-mark-watched \
		--geo-bypass \
		--write-description \
		--write-info-json \
		--write-thumbnail \
		--all-subs \
		--no-mtime \
		--embed-thumbnail \
		--embed-subs \
		--add-metadata"

	# youtube-dl aliases
	alias youtube-dl-best='youtube-dl \
		'"$YOUTUBE_DL_OPTIONS"' \
		--format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" '
	alias youtube-dl-480='youtube-dl \
		'"$YOUTUBE_DL_OPTIONS"' \
		--format "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]" '
	alias youtube-dl-720='youtube-dl \
		'"$YOUTUBE_DL_OPTIONS"' \
		--format "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]" '
	alias youtube-dl-4k='echo -e "This will transcode the video from webm to h264 which could take a long time\n\n"; \
		youtube-dl -f "bestvideo[ext=webm]+bestaudio[ext=m4a]" \
		'"$YOUTUBE_DL_OPTIONS"' \
		--recode-video mp4 '
	alias youtube-dl-playlist='youtube-dl \
		'"$YOUTUBE_DL_OPTIONS"' \
		--download-archive archive.txt \
		--output "./%(playlist_title)s/%(playlist_index)s_%(title)s.%(ext)s" '
	alias youtube-dl-mp3='youtube-dl --extract-audio \
		'"$YOUTUBE_DL_OPTIONS"' \
		--format bestaudio \
		--download-archive archive.txt \
		--audio-format mp3 \
		--no-playlist '
	alias youtube-dl-mp3-playlist='youtube-dl --ignore-errors \
		'"$YOUTUBE_DL_OPTIONS"' \
		--format bestaudio \
		--extract-audio \
		--audio-format mp3 \
		--audio-quality 160K \
		--output "./%(playlist_title)s/%(playlist_index)s_%(title)s.%(ext)s" \
		--yes-playlist '
}


yt-dl-thumb () {
	echo " [running] youtube-dl -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}"
	youtube-dl -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}
}
yt-dl-thumb-fork () {
	echo " [running] yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}"
	yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}
}

alias dl-thumb='yt-dl-thumb'
alias dl-thumb-fork='yt-dl-thumb-fork'

yt-dl-best-test () {
	echo " [running] youtube-dl -v -f \"bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio\" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}"
	youtube-dl -v -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}
}

yt-best-fork () {
	echo " [running] yt-dlp -v -f \"bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio\" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg --write-info-json ${1}"
	yt-dlp -v -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg --write-info-json ${1}
}

dl-split () {
	while IFS="" read -r p || [ -n "$p" ]; do
		yt-best $p
	done < download.txt
}

dl-safe () {
	pyenv activate yt-dlp3 || true
	local url=${1}

	dl-thumb ${url}

	_RETVAL=$?

	if [[ "${_RETVAL}" != "0" ]]; then
			echo "Trying yt-best instead"
			yt-best ${url}

			_RETVAL=$?

			if [[ "${_RETVAL}" != "0" ]]; then
					echo "Trying youtube-dl instead"
					youtube-dl ${url}
			fi
	fi


}

dl-safe-fork () {
	pyenv activate yt-dlp3 || true
	local url=${1}

	# dl-thumb
	dl-thumb-fork ${url}

	_RETVAL=$?

	if [[ "${_RETVAL}" != "0" ]]; then
			echo "Trying yt-best instead"
			yt-best-fork ${url}

			_RETVAL=$?

			if [[ "${_RETVAL}" != "0" ]]; then
					echo "Trying youtube-dl instead"
					yt-dlp --convert-thumbnails jpg ${url}
			fi
	fi


}

alias dlsf='dl-safe-fork'
alias dsf='dl-safe-fork'

sleep_dsf() {
	dsf ${1}
	progress-bar $(python -c "import random;print(random.randint(5,120))")
}

prepare_from_square() {
	pyenv activate ffmpeg-tools399 || true
	ffmpeg-tools -c prepare-from-square -f "$(PWD)" -r
	find . -name "white.jpg" -exec rm -rfv {} \;
}

prepare_from_square_wrong_size() {
	pyenv activate ffmpeg-tools399 || true
	ffmpeg-tools -c prepare-from-square-wrong-size -f "$(PWD)" -r
	find . -name "white.jpg" -exec rm -rfv {} \;
}

dl_tiktok_no_watermark() {
	pyenv activate ffmpeg-tools399 || true
	ffmpeg-tools -c tiktok-no-watermark -f "$(PWD)/download.txt"  --dest "$(PWD)"
}

unzip_rm(){
	unzip \*.zip && rm *.zip
}


yt-crunchyroll () {
	pyenv activate cerebro_bot3 || true
	echo " [running] yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt  --extractor-args \"youtube:player-client=android_embedded,web;include_live_dash\" --extractor-args \"funimation:version=uncut\" -F ${1}"
	yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --extractor-args "youtube:player-client=android_embedded,web;include_live_dash" --extractor-args "funimation:version=uncut" -F ${1}
}

dl-tweet() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] yt-dlp -v -f \"best\" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg ${1}\n"
	yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg ${1}
}

dl-ig() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] gallery-dl --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata ${1}\n"
	gallery-dl --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata ${1}
}

dl-thread() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] gallery-dl --no-mtime --user-agent Wget/1.21.1 --netrc --cookies ~/.config/gallery-dl/cookies-twitter.txt -v -c ~/dev/universityofprofessorex/cerebro-bot/thread.conf ${1}\n"
	gallery-dl --no-mtime --user-agent Wget/1.21.1 --netrc --cookies ~/.config/gallery-dl/cookies-twitter.txt -v -c ~/dev/universityofprofessorex/cerebro-bot/thread.conf ${1}
}

dl-subs() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] yt-dlp -v -f \"best\" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg  --write-subs --sub-langs 'en-orig'  --sub-format srt --write-auto-subs --sub-format srt ${1}\n"
	yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg --write-subs --sub-langs 'en-orig' --sub-format srt --write-auto-subs --sub-format srt ${1}
	# yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-subs --sub-langs 'en' ${1}
	echo -e "\n"
	echo -e "\n"
}

dl-metadata(){
	pyenv activate yt-dlp3 || true
	echo -e " [running] yt-dlp -v -f \"best\" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg  --write-subs --sub-lang en-orig -j ${1} | bat\n"
	yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg --write-subs --sub-lang en-orig -j ${1} | bat
}

ff-subs() {
    fname="${1}"
    predetermined_fname="$(yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg --write-subs --sub-lang en-orig -j ${fname} | jq '.filename')"
    echo $predetermined_fname
    dl-subs "${fname}"
    set -x
    downloaded_mp4="$(echo $predetermined_fname | sed 's,^",,g'| sed 's,"$,,g')"


    outputfile_srt="$(python -c "import pathlib;print(pathlib.Path('$downloaded_mp4').stem)").srt"
    outputfile_with_subs="$(python -c "import pathlib;print(pathlib.Path('$downloaded_mp4').stem)")_with_subs.mp4"

	OIFS="$IFS"
	IFS=$'\n'
    echo -"[running] ffmpeg -y -hide_banner -loglevel warning -i ${downloaded_mp4} -vf subtitles=${outputfile_srt} ${outputfile_with_subs}\n\n"
    ffmpeg -y -hide_banner -loglevel warning -i "${downloaded_mp4}" -vf subtitles=./${outputfile_srt} "${outputfile_with_subs}"
    IFS="$OIFS"

    set +x
}


dl-gallery(){
	pyenv activate yt-dlp3 || true
	uri="${1}"
	echo -e " [running] gallery-dl --no-mtime --netrc -o downloader.http.headers.User-Agent=Wget/1.21.1 -v --write-info-json --write-metadata ${uri}"
	gallery-dl --no-mtime --netrc -o downloader.http.headers.User-Agent=Wget/1.21.1 -v --write-info-json --write-metadata ${uri}
}


prepare_from_large_square() {
        pyenv activate ffmpeg-tools399 || true
        ffmpeg-tools -c prepare-from-large-square -f "$(PWD)" -r
}
prepare_from_large_square_color() {
        pyenv activate ffmpeg-tools399 || true
        ffmpeg-tools -c prepare-from-large-square-identify-color -f "$(PWD)" -r
}

# New best command
# SOURCE: https://www.linuxfordevices.com/tutorials/linux/yt-dlp-download-youtube-videos
dl-only () {
    pyenv activate ffmpeg-tools399 || true
    echo " [running] yt-dlp -v -f 'bv*+ba' -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-dlp-cookies.txt ${1}"
    yt-dlp -v -f 'bv*+ba' -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-dlp-cookies.txt ${1}
}

unzip_nuke() {
  unzip \*.zip && rm *.zip
}

imagemagick_white_jpg(){
    # create white background first
    convert -size 1080x1080 xc:white white.jpg
}

imagemagick_resize_square_batch() {
    imagemagick_white_jpg
    rm -fv loop.txt
    touch loop.txt
    OIFS="$IFS"
    IFS=$'\n'
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.png"`
    do
        echo "file = $file"
        echo imagemagick_resize_square "$file" >> loop.txt
    done
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.jpg"`
    do
        echo "file = $file"
        echo imagemagick_resize_square "$file" >> loop.txt
    done
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.jpeg"`
    do
        echo "file = $file"
        echo imagemagick_resize_square "$file" >> loop.txt
    done
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.JPG"`
    do
        echo "file = $file"
        echo imagemagick_resize_square "$file" >> loop.txt
    done
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.JPEG"`
    do
        echo "file = $file"
        echo imagemagick_resize_square "$file" >> loop.txt
    done

    cat loop.txt
    gsed -i "s,\.\/,'\.\/,g" loop.txt
    gsed -i "s,$,',g" loop.txt
    sort -ru loop.txt > loop.sh
    cat loop.sh
    bash loop.sh
    rm loop.sh
    rm loop.txt
    ls -lta
    IFS="$OIFS"
}


imagemagick_jpg_to_png(){
    mogrify -format png *.JPG
    mogrify -format png *.JPEG
    mogrify -format png *.jpg
    mogrify -format png *.jpeg
    mkdir pngs || true
    mv -fv *.png pngs/
}

webp_to_jpg(){
    magick mogrify -format JPEG *.webp
    mkdir webps || true
    mv -fv *.webp webps/
}

# ----------------------
# adobe
# ----------------------


vault_dev(){
    export VAULT_ADDR="https://vault.dev.or1.adobe.net"

}
vault_prod(){
    export VAULT_ADDR="https://vault.or1.adobe.net"

}

alias fixvideo='sudo killall VDCAssistant'


# bash function to setup eks env vars prior to cluter create or access
eks_env(){
  local num="${1}"

  [[ -z "$num" ]] && { echo "Error: variable num is not set $num"; exit 1; }
  # used to tab completion in vscode etc
  pyenv activate k8s-infrastructure3101 || true

  cd ~/dev/malcolm/k8s-infrastructure4 || true
  # path to manual created cluster config file
  echo -e "Setting CONFIG_LOCATION=$(pwd)/demo${num}.yaml"
  export CONFIG_LOCATION="$(pwd)/demo${num}.yaml"

  # cached version of AWS env vars so that I can use them in multiple windows
  source ~/.aws/cache.be-sandbox

  # Not needed if you are using docker for mac
  # eval $(docker-machine env dev)

  unset KUBECONFIG
  # export KUBECONFIG="$(pwd)/kubeconfig.yaml"

  echo -e "Verify KUBECONFIG is unset = ${KUBECONFIG}"
  echo -e "Verify CONFIG_LOCATION = ${CONFIG_LOCATION}"

  # . "$(brew --prefix asdf)/libexec/asdf.sh"

  kubectl cluster-info

  echo -e "Starting k9s ....\n"

  k9s

}
# bash function to setup eks env vars prior to cluter create or access
kind_env(){
    # used to tab completion in vscode etc
    pyenv activate k8s-infrastructure3101 || true

    cd ~/dev/malcolm/janus || true

    export KUBECONFIG="$(pwd)/kubeconfig.yaml"

    kubectl cluster-info

    k9s

}

eks_sandbox(){
  local num="${1}"

  cd ~/dev/malcolm/k8s-infrastructure2

  [[ -z "$num" ]] && { echo "Error: variable num is not set $num"; exit 1; }
  # used to tab completion in vscode etc
  pyenv activate k8s-infastructure3 || true

  # path to manual created cluster config file
  echo -e "Setting CONFIG_LOCATION=$(pwd)/demo${num}.yaml"
  export CONFIG_LOCATION="$(pwd)/demo${num}.yaml"

  # cached version of AWS env vars so that I can use them in multiple windows
  source ~/.aws/cache.be-sandbox

  # Not needed if you are using docker for mac
  # eval $(docker-machine env dev)

  unset KUBECONFIG
  export KUBECONFIG="$(pwd)/kubeconfig.yaml"

  echo -e "Verify KUBECONFIG is unset = ${KUBECONFIG}"
  echo -e "Verify CONFIG_LOCATION = ${CONFIG_LOCATION}"

  kubectl cluster-info

  echo -e "Starting k9s ....\n"

  cd -

  #   k9s


}


eks_echoserver() {
    eks_sandbox 5
    cd ~/dev/malcolm/echoserver-k8s
    k9s
}

eks_sqs() {
    eks_sandbox 5
    cd ~/dev/malcolm/sqs-pubsub-k8s
    k9s
}

get_1pass(){
    cat ~/.secrets.txt | head -1 | pbcopy
}

alias ssh-bossjones-workstation="ssh -i ~/.ssh/cloudops-beh-app-dev.pem -vvvv -F ~/.ssh/config-balabit ubuntu@10.71.252.237"

get-gpu-ips() {

    aws ec2 describe-instances \
    --filters "Name=instance-type,Values=p2.xlarge" \
    --query "Reservations[*].Instances[*].[PrivateIpAddress]" \
    --output text

}

k8s-e2e(){

    sonobuoy run --wait --level=debug --config=./sonobuoy-config.json
    results=$(sonobuoy retrieve)
    sonobuoy results $results
    sonobuoy delete --wait

}

function dex {
    if docker version &> /dev/null; then
        docker run -v $(pwd):/root/workspace --workdir /root/workspace --rm -ti "$@"
    else
        echo "Docker isn't installed or has not been started."
    fi
}

function dk8s {
    dex --hostname docker-k8s-dev docker-ethos-release.dr-uw2.adobeitc.com/adobe-platform/k8s-toolbox:latest
}

git-fork-sync() {
    git fetch upstream master && git rebase upstream/master
}

git-fork-sync-main() {
    git fetch upstream main && git rebase upstream/main
}

alias lsr='/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister'

function vault-login() {
    export VAULT_ADDR="https://vault-amer.adobe.net"
    export VAULT_TOKEN=$(vault login -token-only -method oidc)
}

# ---------------------------------------------------------
# kubectl
# ---------------------------------------------------------



ethos_kubeconfig() {
    export KUBECONFIG=~/dev/adobe-platform/k8s-kubeconfig/kubeconfig.yaml
    echo "[ethos_kubeconfig] exported KUBECONFIG=${KUBECONFIG}"
    echo "[ethos_kubeconfig] running kubectl config get-contexts"
    kubectl config get-contexts
}

kubectl_get_logs_of_previous_container() {
    # SOURCE: https://wiki.corp.adobe.com/display/~apratina/Kubectl+cheat+sheet
    kubectl -n NAMESPACE logs --previous POD -c CONTAINER
}

kubectl_use_ethos51_stage_va6(){
    local _VERSION=1.18.6
    echo "[kubectl_use_ethos51_stage_va6] switching to correct version kubectl=${_VERSION}"
    asdf global kubectl ${_VERSION}
    echo "[kubectl_use_ethos51_stage_va6] confirming kubectl=${_VERSION}"
    asdf current

    echo "[kubectl_use_ethos51_stage_va6] setting up KUBECONFIG to ethos now"
    ethos_kubeconfig
    echo "[kubectl_use_ethos51_stage_va6] attempting to set context for ethos51-stage-va6"
    kubectl config use-context ethos51-stage-va6

    echo "[kubectl_use_ethos51_stage_va6] sourcing kubectl completion along with ~/.kubectl_fzf.plugin.zsh"
    source <(kubectl completion zsh)
    source ~/.kubectl_fzf.plugin.zsh
}

kubectl_use_ethos51_prod_va6(){
    local _VERSION=1.18.6
    echo "[kubectl_use_ethos51_prod_va6] switching to correct version kubectl=${_VERSION}"
    asdf global kubectl ${_VERSION}
    echo "[kubectl_use_ethos51_prod_va6] confirming kubectl=${_VERSION}"
    asdf current

    echo "[kubectl_use_ethos51_prod_va6] setting up KUBECONFIG to ethos now"
    ethos_kubeconfig
    echo "[kubectl_use_ethos51_prod_va6] attempting to set context for ethos51-prod-va6"
    kubectl config use-context ethos51-prod-va6

    echo "[kubectl_use_ethos51_prod_va6] sourcing kubectl completion along with ~/.kubectl_fzf.plugin.zsh"
    source <(kubectl completion zsh)
    source ~/.kubectl_fzf.plugin.zsh
}

kubectl_cache_builder_for_ethos51_stage_va6(){
    kubectl_use_ethos51_stage_va6
    # DEBUG MODE cache_builder
    cache_builder --logtostderr -v 14
}

kubectl_list_aliases(){
    # https://unix.stackexchange.com/questions/292903/list-names-of-aliases-functions-and-variables-in-zsh
    echo "[kubectl_list_aliases] listing all custom zsh aliases"
    print -rl -- ${(k)aliases} ${(k)functions} ${(k)parameters} | grep "kubectl\|ethos"
}

kubetail_stage_bar_network() {
    echo " [run] kubetail --namespace ns-ethos-e7aa052e69a4e3845f2bd0a1-stage1"
    kubetail --namespace ns-ethos-e7aa052e69a4e3845f2bd0a1-stage1
}

check_cluster_dns() {
    kubectx ${1}
    [[ "${?}" = 1 ]] && return 1
    _NET_TOOLS_CONTAINER_ID=$(kubectl -n menagerie get pods | grep net-tools | cut -d" " -f1)
    _CONTAINER_ID=$(kubectl -n menagerie get pods ${_NET_TOOLS_CONTAINER_ID} -o json | jq '.status.containerStatuses[0].containerID' | sed 's,\",,g'| sed 's,cri\-o\:\/\/,,g')
    echo "${_NET_TOOLS_CONTAINER_ID}"
    kubectl -n menagerie exec -it ${_NET_TOOLS_CONTAINER_ID} -- dig @${2} alex.adobe.net
}

# test -d "${KREW_ROOT:-$HOME/.krew}/bin" && {
#     export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
# }

sed-kubeconfig() {
    gsed -i 's/v1alpha1/v1beta1/' kubeconfig.yaml
    bat kubeconfig.yaml
}

# SOURCE: https://stackoverflow.com/questions/47691479/listing-all-resources-in-a-namespace
# eg. kubectlgetall ns-team-behance--bossjones-ethos-flex-test-deploy--be-0d858c80
function kubectlgetall {
  for i in $(kubectl api-resources --verbs=list --namespaced -o name | grep -v "events.events.k8s.io" | grep -v "events" | sort | uniq); do
    echo "Resource:" $i

    if [ -z "$1" ]
    then
        kubectl get --ignore-not-found ${i} 2>&1 | grep -i -v "Warn" | grep -i -v "Deprecat" | grep -i -v 'https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins'
    else
        kubectl -n ${1} get --ignore-not-found ${i} 2>&1 | grep -i -v "Warn" | grep -i -v "Deprecat"  | grep -i -v 'https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins'
    fi
  done
}

alias k="kubectl"

show_kubeprompt(){
    source ~/dev/kube-ps1/kube-ps1.sh
    PURE_PROMPT_SYMBOL="$(kube_ps1) ❯"
}

kx(){
    show_kubeprompt
    kubectx ${1}
    export PURE_PROMPT_SYMBOL="$(kube_ps1) ❯"
}

alias ck='\cat ~/dev/adobe-platform/k8s-kubeconfig/kubeconfig.yaml | grep name | grep - | grep -v '\''^-'\'' | awk '\''{print $2}'\'

prepare_for_ig_large(){
    # full_path_input_file=$1
    # full_path_output_file=fast.mp4

    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_larger.mp4"
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"

    time ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" \
    -c:v h264_videotoolbox \
    -bufsize 5200K \
    -b:v 5200K \
    -maxrate 5200K \
    -level 42 \
    -bf 2 \
    -g 63 \
    -refs 4 \
    -threads 16 \
    -preset:v fast \
    -vf "scale=1080:1350:force_original_aspect_ratio=decrease,pad=width=1080:height=1350:x=-1:y=-1:color=0x16202A" \
    -c:a aac \
    -ar 44100 \
    -ac 2 \
    "${full_path_output_file}"

}

prepare_for_ig_small(){

    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_smaller.mp4"
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"

    time ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" \
    -c:v h264_videotoolbox \
    -bufsize 5200K \
    -b:v 5200K \
    -maxrate 5200K \
    -level 42 \
    -bf 2 \
    -g 63 \
    -refs 4 \
    -threads 16 \
    -preset:v fast \
    -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=width=1080:height=1080:x=-1:y=-1:color=0x16202A" \
    -c:a aac \
    -ar 44100 \
    -ac 2 \
    "${full_path_output_file}"

}

get_primary_color(){

    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_primary_color.png"

    ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" -ss 00:00:01 -vframes 1 "${full_path_output_file}" > /dev/null 2>&1

    primary_color="0x$(magick identify -format "%[hex:p{1,1}]" ${full_path_output_file})"
    echo $primary_color
    rm -f "${full_path_output_file}"
}

prepare_for_ig_large_primary_color(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_larger_pc.mp4"
    primary_color=$(get_primary_color "${full_path_input_file}")
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    echo -e "primary_color: ${primary_color}\n"

    time ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" \
    -c:v h264_videotoolbox \
    -bufsize 5200K \
    -b:v 5200K \
    -maxrate 5200K \
    -level 42 \
    -bf 2 \
    -g 63 \
    -refs 4 \
    -threads 16 \
    -preset:v fast \
    -vf "scale=1080:1350:force_original_aspect_ratio=decrease,pad=width=1080:height=1350:x=-1:y=-1:color=${primary_color}" \
    -c:a aac \
    -ar 44100 \
    -ac 2 \
    "${full_path_output_file}"

}

prepare_for_ig_small_primary_color(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_smaller_pc.mp4"
    primary_color=$(get_primary_color "${full_path_input_file}")
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    echo -e "primary_color: ${primary_color}\n"

    time ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" \
    -c:v h264_videotoolbox \
    -bufsize 5200K \
    -b:v 5200K \
    -maxrate 5200K \
    -level 42 \
    -bf 2 \
    -g 63 \
    -refs 4 \
    -threads 16 \
    -preset:v fast \
    -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=width=1080:height=1080:x=-1:y=-1:color=${primary_color}" \
    -c:a aac \
    -ar 44100 \
    -ac 2 \
    "${full_path_output_file}"

}

mov_to_mp4(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)").mp4"
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    time ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" \
    -c:v h264_videotoolbox \
    -c:a aac \
    -strict experimental \
    -bufsize 5200K \
    -b:v 5200K \
    -maxrate 5200K \
    -level 42 \
    -bf 2 \
    -g 63 \
    -refs 4 \
    -threads 16 \
    -preset:v fast "${full_path_output_file}"
}

# ---------------------------------------------------------
# chezmoi managed - end.zsh
# ---------------------------------------------------------
