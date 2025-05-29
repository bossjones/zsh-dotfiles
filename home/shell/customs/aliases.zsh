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
    python aioscraper/cli.py scrape -- "${fname}"
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
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo scenedetect -i "$filename" -o processed/ split-video; done >> redo.sh
    echo "Script created. cat redo.sh"
    cat redo.sh
    chmod +x redo.sh
    mkdir -p processed/ || true
    ./redo.sh
}

split_scenes_content(){
    pyenv activate yt-dlp3 || true
    echo '#!/usr/bin/env bash' > redo.sh
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo scenedetect -i "$filename" detect-content --threshold 70.0 split-video -o processed/; done >> redo.sh
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
alias dotfiles_provision_branch='chezmoi init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git --branch feature-rye'
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
	youtube-dl -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg "${1}"
}
yt-dl-thumb-fork () {
	echo " [running] yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}"
	yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg "${1}"
}

alias dl-thumb='yt-dl-thumb'
alias dl-thumb-fork='yt-dl-thumb-fork'

yt-dl-best-test () {
	echo " [running] youtube-dl -v -f \"bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio\" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg ${1}"
	youtube-dl -v -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg "${1}"
}

yt-best-fork () {
	echo " [running] yt-dlp -v -f \"bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio\" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg --write-info-json ${1}"
	yt-dlp -v -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg --write-info-json "${1}"
}

yt-red () {
	echo " [running] yt-dlp -v -f hd -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg --write-info-json ${1}"
	yt-dlp -v -f hd -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg --write-info-json "${1}"
}

dl-split () {
	while IFS="" read -r p || [ -n "$p" ]; do
		yt-best "$p"
	done < download.txt
}

dl-safe () {
	pyenv activate yt-dlp3 || true
	local url=${1}

	dl-thumb "${url}"

	_RETVAL=$?

	if [[ "${_RETVAL}" != "0" ]]; then
			echo "Trying yt-best instead"
			yt-best "${url}"

			_RETVAL=$?

			if [[ "${_RETVAL}" != "0" ]]; then
					echo "Trying youtube-dl instead"
					youtube-dl "${url}"
			fi
	fi


}

dl-safe-fork () {
	pyenv activate yt-dlp3 || true
	local url=${1}

	# dl-thumb
	dl-thumb-fork "${url}"

	_RETVAL=$?

	if [[ "${_RETVAL}" != "0" ]]; then
			echo "Trying yt-best instead"
			yt-best-fork "${url}"

			_RETVAL=$?

			if [[ "${_RETVAL}" != "0" ]]; then
					echo "Trying youtube-dl instead"
					yt-dlp --convert-thumbnails jpg "${url}"
			fi
	fi


}

alias dlsf='dl-safe-fork'
alias dsf='dl-safe-fork'

sleep_dsf() {
	dsf "${1}"
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

json_rm(){
	rm *.json
}


yt-crunchyroll () {
	pyenv activate cerebro_bot3 || true
	echo " [running] yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt  --extractor-args \"youtube:player-client=android_embedded,web;include_live_dash\" --extractor-args \"funimation:version=uncut\" -F ${1}"
	yt-dlp -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --extractor-args "youtube:player-client=android_embedded,web;include_live_dash" --extractor-args "funimation:version=uncut" -F "${1}"
}

dl-tweet() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] yt-dlp -v -f \"best\" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg ${1}\n"
	yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg" ${1}"
}

dl-ig() {
	pyenv activate yt-dlp3 || true
	echo -e " [running]  gallery-dl --cookies-from-browser Firefox --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata  ${1}\n"
	gallery-dl --cookies-from-browser Firefox --no-mtime --user-agent Wget/1.21.1 -v --write-info-json --write-metadata  "${1}"
}

# download using Firefox cookies
dsfi() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] yt-dlp -v -f \"best\" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies-from-browser Firefox --write-info-json --convert-thumbnails jpg ${1}\n"
	yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies-from-browser Firefox --write-info-json --convert-thumbnails jpg "${1}"
}

dl-thread() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] gallery-dl --no-mtime --user-agent Wget/1.21.1 --netrc --cookies ~/.config/gallery-dl/cookies-twitter.txt -v -c ~/dev/universityofprofessorex/cerebro-bot/thread.conf ${1}\n"
	gallery-dl --no-mtime --user-agent Wget/1.21.1 --netrc --cookies ~/.config/gallery-dl/cookies-twitter.txt -v -c ~/dev/universityofprofessorex/cerebro-bot/thread.conf "${1}"
}

dl-subs() {
	pyenv activate yt-dlp3 || true
	echo -e " [running] yt-dlp -v -f \"best\" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg  --write-subs --sub-langs 'en-orig'  --sub-format srt --write-auto-subs --sub-format srt ${1}\n"
	yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg --write-subs --sub-langs 'en-orig' --sub-format srt --write-auto-subs --sub-format srt "${1}"
	# yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-subs --sub-langs 'en' ${1}
	echo -e "\n"
	echo -e "\n"
}

dl-metadata(){
	pyenv activate yt-dlp3 || true
	echo -e " [running] yt-dlp -v -f \"best\" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg  --write-subs --sub-lang en-orig -j ${1} | bat\n"
	yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg --write-subs --sub-lang en-orig -j "${1}" | bat
}

ff-subs() {
    fname="${1}"
    predetermined_fname="$(yt-dlp -v -f "best" -n --ignore-errors --restrict-filenames --write-thumbnail --embed-thumbnail --no-mtime --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json --convert-thumbnails jpg --write-subs --sub-lang en-orig -j "${fname}" | jq '.filename')"
    echo "$predetermined_fname"
    dl-subs "${fname}"
    set -x
    downloaded_mp4="$(echo "$predetermined_fname" | sed 's,^",,g'| sed 's,"$,,g')"


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
	gallery-dl --no-mtime --netrc -o downloader.http.headers.User-Agent=Wget/1.21.1 -v --write-info-json --write-metadata "${uri}"
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
    yt-dlp -v -f 'bv*+ba' -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-dlp-cookies.txt "${1}"
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

heic_to_jpg(){
    mogrify -format jpg *.HEIC
    mkdir heics || true
    mv -fv *.HEIC heics/
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
    sonobuoy results "$results"
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
    kubectx "${1}"
    [[ "${?}" = 1 ]] && return 1
    _NET_TOOLS_CONTAINER_ID=$(kubectl -n menagerie get pods | grep net-tools | cut -d" " -f1)
    _CONTAINER_ID=$(kubectl -n menagerie get pods "${_NET_TOOLS_CONTAINER_ID}" -o json | jq '.status.containerStatuses[0].containerID' | sed 's,\",,g'| sed 's,cri\-o\:\/\/,,g')
    echo "${_NET_TOOLS_CONTAINER_ID}"
    kubectl -n menagerie exec -it "${_NET_TOOLS_CONTAINER_ID}" -- dig @"${2}" alex.adobe.net
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
    echo "Resource:" "$i"

    if [ -z "$1" ]
    then
        kubectl get --ignore-not-found "${i}" 2>&1 | grep -i -v "Warn" | grep -i -v "Deprecat" | grep -i -v 'https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins'
    else
        kubectl -n ${1} get --ignore-not-found "${i}" 2>&1 | grep -i -v "Warn" | grep -i -v "Deprecat"  | grep -i -v 'https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins'
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
    kubectx "${1}"
    export PURE_PROMPT_SYMBOL="$(kube_ps1) ❯"
}

alias ck='\cat ~/dev/adobe-platform/k8s-kubeconfig/kubeconfig.yaml | grep name | grep - | grep -v '\''^-'\'' | awk '\''{print $2}'\'

get_open_ports(){
    lsof -i -P | grep -i "listen"
}

prepare_for_ig_large(){
    # full_path_input_file=$1
    # full_path_output_file=fast.mp4

    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_larger.mp4"
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    get_timestamp=$(gstat -c %y "${full_path_input_file}")

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
    set_timestamp=$(gtouch -d "$get_timestamp" "${full_path_output_file}")

}

prepare_for_ig_small(){

    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_smaller.mp4"
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    get_timestamp=$(gstat -c %y "${full_path_input_file}")

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
    set_timestamp=$(gtouch -d "$get_timestamp" "${full_path_output_file}")

}

get_primary_color(){

    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_primary_color.png"

    ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" -ss 00:00:01 -vframes 1 "${full_path_output_file}" > /dev/null 2>&1

    primary_color="0x$(magick identify -format "%[hex:p{1,1}]" "${full_path_output_file}")"
    echo "$primary_color"
    rm -f "${full_path_output_file}"
}

prepare_for_ig_large_primary_color(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_larger_pc.mp4"
    primary_color=$(get_primary_color "${full_path_input_file}")
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    echo -e "primary_color: ${primary_color}\n"
    get_timestamp=$(gstat -c %y "${full_path_input_file}")

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
    set_timestamp=$(gtouch -d "$get_timestamp" "${full_path_output_file}")

}

prepare_for_ig_small_primary_color(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_smaller_pc.mp4"
    primary_color=$(get_primary_color "${full_path_input_file}")
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    echo -e "primary_color: ${primary_color}\n"
    get_timestamp=$(gstat -c %y "${full_path_input_file}")

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
    set_timestamp=$(gtouch -d "$get_timestamp" "${full_path_output_file}")

}

mov_to_mp4(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)").mp4"
    get_timestamp=$(gstat -c %y "${full_path_input_file}")
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
    set_timestamp=$(gtouch -d "$get_timestamp" "${full_path_output_file}")
}

klam_env() {
    echo "setting klam env to us-west-2 ..."
    export KLAM_BROWSER="Google Chrome"
    export AWS_DEFAULT_REGION=us-west-2
}

get_all_images(){
    image_list=$(fd -a --ignore -p -e jpg -e png -e jpeg --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*')
    echo "$image_list"
}

get_all_videos(){
    video_list=$(fd -a --ignore -p -e mp4 --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*')
    echo "$video_list"
}

image_prepare_primary_color(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}_larger{p.suffix}\")")"
    primary_color=$(magick "${full_path_input_file}" -format "%[hex:p{0,0}]" info:)
    get_timestamp=$(gstat -c %y "${full_path_input_file}")

    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    echo -e "primary_color: ${primary_color}\n"

    convert -size 1080x1350 xc:#"${primary_color}" background.png

    magick "${full_path_input_file}" -resize 1080x1350 -background "#${primary_color}" -compose Copy -gravity center -extent 1080x1350 -quality 92 "${full_path_output_file}"
    rm -f background.png
    set_timestamp=$(gtouch -d "$get_timestamp" "${full_path_output_file}")
}

prepare_images_pc(){
    fd -a --max-depth=1 --ignore -p -e jpg -e png -e jpeg --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'image_prepare_primary_color "$1"' zsh
}

prepare_videos_pc(){
    fd -a --max-depth=1 --ignore -p -e mp4 --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'prepare_for_ig_large_primary_color "$1"' zsh
}

prepare_dir_all(){
    prepare_images_pc
    prepare_videos_pc
}

alias prepare_all="prepare_dir_all"

# -

# Normalized version
prepare_images_n(){
    fd -a --max-depth=1 --ignore -p -e jpg -e png -e jpeg --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'image_prepare_primary_color "$1"' zsh
}

prepare_videos_n(){
    fd -a --max-depth=1 --ignore -p -e mp4 --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'prepare_for_ig_large "$1"' zsh
}

prepare_dir_all_n(){
    prepare_images_n
    prepare_videos_n
}

alias prepare_all_n="prepare_dir_all_n"

dl-hls() {
    # SOURCE: https://forum.videohelp.com/threads/403670-How-do-I-use-yt-dlp-to-retrieve-a-streaming-video
    pyenv activate yt-dlp3 || true
    # yt-dlp -S 'res:500' --downloader ffmpeg --downloader-args "ffmpeg:-t 180" -o testingytdlp-180.mp4 --cookies=~/Downloads/yt-cookies.txt ${1}
    yt-dlp -S 'res:500' --downloader ffmpeg -o $(uuidgen).mp4 --cookies=~/Downloads/yt-cookies.txt "${1}"
}

dl-hls-b() {
    # SOURCE: https://forum.videohelp.com/threads/403670-How-do-I-use-yt-dlp-to-retrieve-a-streaming-video
    pyenv activate yt-dlp3 || true
    # yt-dlp -S 'res:500' --downloader ffmpeg --downloader-args "ffmpeg:-t 180" -o testingytdlp-180.mp4 --cookies=~/Downloads/yt-cookies.txt ${1}
    yt-dlp -S 'res:500' --downloader ffmpeg -o $(uuidgen).mp4 --cookies-from-browser chrome:/Users/malcolm/Library/Application\ Support/Google/Chrome/Profile\ 11 "${1}"
}

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


prepare_videos_small(){
    fd -a --max-depth=1 --ignore -p -e mp4 --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'prepare_for_ig_small "$1"' zsh
}

prepare_dir_small(){
    prepare_images_pc
    prepare_videos_small
}

alias prepare_all_small="prepare_dir_small"

dl-twitter() {
    pyenv activate yt-dlp3 || true
    echo " [running]: gallery-dl --no-mtime -v --write-info-json --write-metadata ${1}"
    gallery-dl --no-mtime -v --write-info-json --write-metadata "${1}"
}

alias dlt="dl-twitter"

download_file() {
  # Check if the argument is provided
  if [ -z "$1" ]; then
    echo "Error: URL argument is missing."
    echo "Usage example: "
    echo 'download_file "https://d2dsm5y8gyd937.cloudfront.net/82K9-0R59AC4T8B71IVKU.mp4"'
    return 1
  fi

  # Parse the filename from the URL
  filename=$(basename "$1")

  # Use curl to download the file
  curl -o "$filename" "$1"

  # Check if the download was successful
  if [ $? -eq 0 ]; then
    echo "Download successful. File saved as: $filename"
  else
    echo "Error: Download failed."
  fi
}

dl-sub () {
	echo " [running] yt-dlp -v --embed-subs --cookies=~/Downloads/yt-cookies.txt --write-auto-sub --sub-lang en -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --convert-thumbnails jpg ${1}"
	yt-dlp -v --embed-subs --cookies=~/Downloads/yt-cookies.txt --skip-download --write-auto-sub --sub-lang en "${1}"
	yt-dlp -v --embed-subs --cookies=~/Downloads/yt-cookies.txt --write-auto-sub --sub-lang en -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --convert-thumbnails jpg "${1}"
}

# convert image cover for video
ap () {
    # vid="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    # img="$(python -c "import pathlib;p=pathlib.Path('${2}');print(f\"{p.stem}{p.suffix}\")")"
    # echo -e "vid: ${vid}\n"
    # echo -e "img: ${img}\n"
    # echo -e " [run]: AtomicParsley $vid --artwork $img\n"
    # AtomicParsley $vid --artwork $img
    AtomicParsley "$1" --artwork "$2"
}

re_encode_videos(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    full_path_output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_reencoded.mp4"
    primary_color=$(get_primary_color "${full_path_input_file}")
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "full_path_output_file: ${full_path_output_file}\n"
    echo -e "primary_color: ${primary_color}\n"

    ffmpeg \
    -y \
    -hide_banner -loglevel warning \
    -i "${full_path_input_file}" \
    "${full_path_output_file}"

}

prepare_re_encode(){
    fd -a --ignore -p -e mp4 --exclude '*reencoded*' -x zsh -ic 're_encode_videos "$1"' zsh
}

mp4_to_images(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    prefix_output_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}\")")"
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "prefix_output_file: ${prefix_output_file}\n"
    ffmpeg -i "${full_path_input_file}" "${prefix_output_file}"%04d.png
}

prepare_mp4_to_images(){
    fd -a --ignore -p -e mp4 -x zsh -ic 'mp4_to_images "$1"' zsh
}

mv_orig_media(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    mkdir -p orig || true
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo "cp -a \"${full_path_input_file}\" orig/"
    echo "rm -fv \"${full_path_input_file}\""
    echo ""
    cp -a "${full_path_input_file}" orig/
    rm -fv "${full_path_input_file}"
    echo ""
}

prepare_orig(){
    fd -a --max-depth=1 --ignore -p -e jpg -e png -e jpeg -e mp4 -e mov --threads=10 --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'mv_orig_media "$1"' zsh
}

show_images_pc(){
    # fd --absolute-path --ignore --full-path -e jpg -e png -e jpeg --exclude '*larger*' --exclude '*smaller*' --exec zsh -ic 'echo "$1"' zsh
    fd --absolute-path --ignore --full-path -e jpg -e png -e jpeg --exclude '*large*' --exclude '*small*' --exclude '*ig_reel*' --exclude '*ig_story*'
}

show_videos_pc(){
    # fd --absolute-path --ignore --full-path -e mp4 --exclude '*larger*' --exclude '*smaller*' --exec zsh -ic 'echo "$1"' zsh
    fd --absolute-path --ignore --full-path -e mp4 --exclude '*large*' --exclude '*small*' --exclude '*ig_reel*' --exclude '*ig_story*'
}

show_dir_all(){
    show_images_pc
    show_videos_pc
}

alias show_all="show_dir_all"


gif_to_mp4(){
    full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    prefix_output_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}\")")"
    echo -e "full_path_input_file: ${full_path_input_file}\n"
    echo -e "prefix_output_file: ${prefix_output_file}\n"
    ffmpeg -i "${full_path_input_file}" -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "${prefix_output_file}.mp4"
}


prepare_gif(){
    fd -a --max-depth=1 --ignore -p -e gif --threads=10 --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'gif_to_mp4 "$1"' zsh
    rm -fv *.gif
}

prepare_mov_to_mp4(){
    fd -a --max-depth=1 --ignore -p -e mov --threads=10 --exclude '*larger*' --exclude '*smaller*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'mov_to_mp4 "$1"' zsh
    rm -fv *.mov
    rm -fv *.MOV
}

prepare_everything(){
    ulimit -n 65536
    prepare_gif
    unzip_rm
    json_rm
    webp_to_jpg
    heic_to_jpg
    prepare_mov_to_mp4
    prepare_all
    prepare_orig
}

prepare_everything_small(){
    ulimit -n 65536

    prepare_gif
    unzip_rm
    json_rm
    webp_to_jpg
    heic_to_jpg
    prepare_mov_to_mp4
    prepare_all_small
    prepare_orig
}

generate_video_thumbnail() {
    # set -e

    is_docker() {
        [ -f /.dockerenv ] ||
        grep -q docker /proc/1/cgroup ||
        [ -n "$container" ] ||
        [[ "$(hostname)" == *"docker"* ]]
    }

    get_os() {
        os="$(uname -s)"
        if [ "$os" = Darwin ]; then
            echo "macos"
        elif [ "$os" = Linux ]; then
            echo "linux"
        else
            echo "unsupported OS: $os"
            return 1
        fi
    }

    get_arch() {
        arch="$(uname -m)"
        if [ "$arch" = x86_64 ]; then
            echo "x64"
        elif [ "$arch" = aarch64 ] || [ "$arch" = arm64 ]; then
            echo "arm64"
        else
            echo "unsupported architecture: $arch"
            return 1
        fi
    }

    is_macos() {
        [ "$(get_os)" = "macos" ]
    }


    # Check for required binaries
    check_dependency() {
        if ! command -v $1 &> /dev/null; then
            echo "Error: $1 is not installed. Please install it and try again."
            echo "You can typically install it using your package manager:"
            echo "For Ubuntu/Debian: sudo apt-get install $1"
            echo "For macOS with Homebrew: brew install $1"
            echo "For Ubuntu/Debian try: apt install -y curl git gnupg zsh tar software-properties-common vim fzf perl gettext direnv vim awscli wget build-essential bash-completion sudo ffmpeg bc gawk libmediainfo-dev fd-find"
            echo "For MacOS try: brew install curl git gnupg zsh fzf perl gettext direnv vim awscli wget bash-completion ffmpeg gawk libmediainfo"
            return 1
        fi
    }

    # Function to install packages
    install_packages() {
        if is_macos; then
            if ! command -v brew >/dev/null 2>&1; then
                echo "Homebrew is not installed. Please install it first."
                return 1
            fi
        fi

        check_dependency ffmpeg
        check_dependency ffprobe
        check_dependency bc
        check_dependency gawk
        check_dependency pyvideothumbnailer

    }

    # install_packages || return 1

    if [ $# -eq 0 ]; then
        echo "Please provide the video file path as an argument." >&2
        return 1
    fi

    video_file="$1"
    if [ ! -f "$video_file" ]; then
        echo "Video file not found: $video_file" >&2
        return 1
    fi

    # Get the absolute path of the video file
    absolute_path=$(python3 -c "import os; print(os.path.abspath('$video_file'))")

    # Get the parent directory
    parent_dir=$(dirname "$absolute_path")

    # Get the relative path
    relative_path=$(basename "$absolute_path")

    echo -e "******************************************\n"
    echo "absolute_path: $absolute_path"
    echo "parent_dir: $parent_dir"
    echo "relative_path: $relative_path"
    echo -e "******************************************\n"

    echo "Processing video file: $relative_path"

    # Change to the parent directory
    cd "$parent_dir" || return 1

    echo "running: pyvideothumbnailer --suffix __preview --override-existing \"$relative_path\""
    # Run pyvideothumbnailer with the relative path
    if ! pyvideothumbnailer --suffix __preview --override-existing "$relative_path"; then
        echo "Error: pyvideothumbnailer failed to process the video."
        return 1
    fi

    echo "Thumbnail created successfully."
}

# # Prepare videos for classification by:
# # 1. Finding all video files (mp4, avi, mov, mkv)
# # 2. Converting first 3 seconds to a 320px wide GIF at 10fps
# # 3. Using palettegen/paletteuse for better GIF color quality
# # 4. Moving original files to orig/ directory
# prepare_for_classifer(){
#     fd -e mp4 -e avi -e mov -e mkv -i -x ffmpeg -y -i {} -filter_complex "[0:v] select='between(t,0,3)',setpts=PTS-STARTPTS,fps=10,scale=320:-1,split [a][b];[a] palettegen [p];[b][p] paletteuse" {.}.gif
#     prepare_orig
# }
prepare_for_classifer(){
    ulimit -n 65536

    if command -v pyvideothumbnailer >/dev/null 2>&1; then
        echo "pyvideothumbnailer is installed"
        if command -v fdfind >/dev/null 2>&1; then
            fdfind -a --max-depth=1 --ignore-case -p -e mp4 -e avi -e mov -e mkv --threads=10  --exclude '*preview*' -x zsh -ic 'generate_video_thumbnail "$1"' zsh
        else
            fd -a --max-depth=1 --ignore -p -e mp4 -e avi -e mov -e mkv --threads=10  --exclude '*preview*' --exclude '*ig_reel*' --exclude '*ig_story*' -x zsh -ic 'generate_video_thumbnail "$1"' zsh
        fi

        prepare_orig

        # fd -a --max-depth=1 --ignore -p -e mp4 -e avi -e mov -e mkv --threads=10 -x zsh -ic 'generate_video_thumbnail "$1"' zsh

        # # fd -e mp4 -e avi -e mov -e mkv -i -x ffmpeg -y -i {} -filter_complex "[0:v] select='between(t,0,3)',setpts=PTS-STARTPTS,fps=10,scale=320:-1,split [a][b];[a] palettegen [p];[b][p] paletteuse" {.}.gif
        # prepare_orig
    else
        echo "pyvideothumbnailer is not installed"
        return 1
    fi

}

get_current_python_interpreter(){
    python -c "import sys;print(sys.executable)"
}


extract_first_frame() {
    input_file="$1"
    output_file="${input_file%.mp4}.jpg"
    ffmpeg -y -i "$input_file" -vframes 1 -q:v 2 "$output_file" -loglevel error
}

# Main script
prepare_first_frame() {
    # Check if ffmpeg is installed
    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: ffmpeg is not installed. Please install ffmpeg to use this script."
        exit 1
    fi

    # Loop through all MP4 files in the current directory
    for file in *.mp4; do
        # Check if there are any MP4 files
        if [ -e "$file" ]; then
            echo "Processing $file..."
            extract_first_frame "$file"
            echo "Saved first frame as ${file%.mp4}.jpg"
        else
            echo "No MP4 files found in the current directory."
            exit 0
        fi
    done

    echo "All MP4 files processed successfully."
}



alias reddit_dl='yt-best-fork'
alias red_dl='yt-red'

reddit_dl_improved(){
    echo " [running] gallery-dl --config ~/.gallery-dl.conf --no-mtime -v --write-info-json --write-metadata --cookies ~/.config/gallery-dl/wavy-cookies-instagram.txt ${1}"
    gallery-dl --config ~/.gallery-dl.conf --no-mtime -v --write-info-json --write-metadata --cookies ~/.config/gallery-dl/wavy-cookies-instagram.txt ${1}
}

alias rdi='reddit_dl_improved'

download_magnet(){
    # aria2c -d ~/Downloads --seed-time=0 "magnet:?xt=urn:btih:248D0A1CD08284299DE78D5C1ED359BB46717D8C"
    echo 'aria2c -d ~/Downloads --seed-time=0 "${1}"'
    # aria2c -d ~/Downloads --seed-time=0 "${1}"
}

kernel_tuning(){
    cat << EOF | sudo tee /etc/security/limits.d/limits.conf
# see /usr/lib/pam/limits.conf for documentation
# see docs/kernel.md for more details
# update the docs if updating this file
#
# 1048576 == 2**20; https://stackoverflow.com/a/1213069/4179075
* soft nofile 1048576
* hard nofile 1048576
EOF
    cat << EOF | sudo tee /etc/sysctl.d/00-kernel-tuning.conf
# See docs/kernel.md for details (please **update docs/kernel.md** if updating this file)
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=128000
fs.suid_dumpable=0
kernel.core_pattern=|/dev/null
kernel.dmesg_restrict=1
kernel.pid_max=4194304
net.core.netdev_max_backlog=300000
net.core.rmem_default=1048576
net.core.rmem_max=10485760
net.core.somaxconn=16384
net.core.wmem_default=1048576
net.core.wmem_max=10485760
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.default.log_martians=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
# net.ipv4.ip_local_port_range=1024 65535
net.ipv4.neigh.default.gc_thresh1=80000
net.ipv4.neigh.default.gc_thresh2=90000
net.ipv4.neigh.default.gc_thresh3=100000
net.ipv4.tcp_ecn=1
net.ipv4.tcp_keepalive_intvl=90
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_time=120
net.ipv4.tcp_max_syn_backlog=32768
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_rmem=4096 1048576 10485760
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_wmem=4096 1048576 10485760
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_ra=0
net.ipv6.conf.default.accept_redirects=0
net.ipv6.conf.default.accept_source_route=0
net.netfilter.nf_conntrack_buckets=524288
net.netfilter.nf_conntrack_max=2097152
vm.max_map_count=262144
EOF
    sudo sysctl -p /etc/sysctl.d/00-kernel-tuning.conf

}

more_kernel_tuning(){
    cat << EOF | sudo tee /etc/modules-load.d/nf.conf
nf_conntrack
EOF
    cat << EOF | sudo tee /etc/systemd/network/20-dnsmasq.network
[Match]
Name=dnsmasq*

[Link]
Unmanaged=yes
EOF
    cat << EOF | sudo tee /etc/systemd/network/21-dummy.network
[Match]
Name=dummy*

[Link]
Unmanaged=yes
EOF
}

# examples:
#     ./execsnoop                      # trace all exec() syscalls
#     ./execsnoop -x                   # include failed exec()s
#     ./execsnoop -T                   # include time (HH:MM:SS)
#     ./execsnoop -P 181               # only trace new processes whose parent PID is 181
#     ./execsnoop -U                   # include UID
#     ./execsnoop -u 1000              # only trace UID 1000
#     ./execsnoop -u user              # get user UID and trace only them
#     ./execsnoop -t                   # include timestamps
#     ./execsnoop -q                   # add "quotemarks" around arguments
#     ./execsnoop -n main              # only print command lines containing "main"
#     ./execsnoop -l tpkg              # only print command where arguments contains "tpkg"
#     ./execsnoop --cgroupmap mappath  # only trace cgroups in this BPF map
#     ./execsnoop --mntnsmap mappath   # only trace mount namespaces in the map

# examples:
#     ./opensnoop                        # trace all open() syscalls
#     ./opensnoop -T                     # include timestamps
#     ./opensnoop -U                     # include UID
#     ./opensnoop -x                     # only show failed opens
#     ./opensnoop -p 181                 # only trace PID 181
#     ./opensnoop -t 123                 # only trace TID 123
#     ./opensnoop -u 1000                # only trace UID 1000
#     ./opensnoop -d 10                  # trace for 10 seconds only
#     ./opensnoop -n main                # only print process names containing "main"
#     ./opensnoop -e                     # show extended fields
#     ./opensnoop -f O_WRONLY -f O_RDWR  # only print calls for writing
#     ./opensnoop -F                     # show full path for an open file with relative path
#     ./opensnoop --cgroupmap mappath    # only trace cgroups in this BPF map
#     ./opensnoop --mntnsmap mappath     # only trace mount namespaces in the map

# examples:
#     ./ext4slower             # trace operations slower than 10 ms (default)
#     ./ext4slower 1           # trace operations slower than 1 ms
#     ./ext4slower -j 1        # ... 1 ms, parsable output (csv)
#     ./ext4slower 0           # trace all operations (warning: verbose)
#     ./ext4slower -p 185      # trace PID 185 only

# system_analysis_bcc() {
#     mkdir -p ~/analysis/$(date +%Y%m%d)/ || true
# #   sudo /usr/share/bcc/tools/opensnoop -TUe
#     sudo /bin/python3 /usr/share/bcc/tools/execsnoop -xTUt > ~/analysis/$(date +%Y%m%d)/execsnoop.log
#     sudo /bin/python3 /usr/share/bcc/tools/opensnoop -TUFe -d 10 > ~/analysis/$(date +%Y%m%d)/opensnoop.log
#     sudo /bin/python3 /usr/share/bcc/tools/ext4slower > ~/analysis/$(date +%Y%m%d)/ext4slower.log
# #   sudo /bin/python3 /usr/share/bcc/tools/sofdsnoop -d 10
# #   sudo /bin/python3 /usr/share/bcc/tools/syscount
# #   sudo /bin/python3 /usr/share/bcc/tools/syscount -P
# #   sudo /bin/python3 /usr/share/bcc/tools/syscount -P -d 30
# #   sudo /bin/python3 /usr/share/bcc/tools/ext4dist -m 5
# execsnoop
# opensnoop
# ext4slower (or btrfs*, xfs*, zfs*)
# biolatency
# biosnoop
# cachestat
# tcpconnect
# tcpaccept
# tcpretrans
# runqlat
# profile



# }

git_search(){
    set -x
    git log -S "${1}"
    set +x
}

git_clone_d(){
    git clone --depth 1 "${1}"
}

alias gcd='git_clone_d'

alias kge="kubectl get events --sort-by='.lastTimestamp'"

fetch_subs () {
    # SOURCE: https://github.com/wtechgo/vidhop-linux/blob/master/bin/dlv
    pyenv activate yt-dlp3 || true
    # subs provided by the uploader. https://www.science.co.il/language/Codes.php
    yt-dlp --cookies=~/Downloads/yt-cookies.txt \
        --write-subs --convert-subs "srt" --sub-langs="en.*" \
        --restrict-filenames \
        --no-download ${1}

    # autogenerated subs
    yt-dlp --cookies=~/Downloads/yt-cookies.txt \
        --write-auto-subs --convert-subs "srt" --sub-langs="en.*" \
        --restrict-filenames \
        --no-download ${1}
}

fetch_thumbnail() {
    # SOURCE: https://github.com/wtechgo/vidhop-linux/blob/master/bin/dlv
    pyenv activate yt-dlp3 || true
    yt-dlp --cookies=~/Downloads/yt-cookies.txt \
        --write-thumbnail --convert-thumbnails jpg \
        --restrict-filenames \
        --no-download --verbose ${1}
}

dl-sub () {
    pyenv activate yt-dlp3 || true
	echo " [running] yt-dlp -v --embed-subs --cookies=~/Downloads/yt-cookies.txt --write-auto-sub --sub-lang en -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --convert-thumbnails jpg ${1}"
	yt-dlp -v --embed-subs --cookies=~/Downloads/yt-cookies.txt --write-auto-sub --sub-lang en -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --convert-thumbnails jpg ${1}
}

alias kge="kubectl get events --sort-by='.lastTimestamp'"

curl_download() {
  echo "downloading $1 config: $2"
  curl -fsSL "$1" -o "./$2"
}


bump_ulimit(){
    ulimit -n 70000
}


resize_twitter_list_banner() {

    local OIFS="$IFS"
    IFS=$'\n'

    if [ $# -ne 2 ]; then
        echo "Usage: resize_twitter_list_banner <input_file> <output_file>"
        return 1
    fi

    local input_file="$1"
    local output_file="$2"

    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist."
        return 1
    fi

    magick "$input_file" \
        -resize 1500x500 \
        -background white \
        -gravity center \
        -extent 1500x500 \
        "$output_file"

    echo "Resized image saved as $output_file"
    IFS="$OIFS"
}

convert_flv_to_mp4() {
    fname="${1}"
    outputfile="$(python -c "import pathlib;print(pathlib.Path('$fname').stem)").mp4"
    echo $fname
    echo $outputfile
    echo "[running] ffmpeg -y -i \"${fname}\" -c:v libx264 -crf 19 -strict experimental \"${outputfile}\""
    ffmpeg -y -i "${fname}" -c:v libx264 -crf 19 -strict experimental "${outputfile}"
}

convert_wmv_to_mp4() {
    fname="${1}"
    outputfile="$(python -c "import pathlib;print(pathlib.Path('$fname').stem)").mp4"
    echo $fname
    echo $outputfile
    echo "[running] ffmpeg -y -i \"${fname}\" -c:v libx264 -crf 23 -profile:v high -r 30 -c:a aac -q:a 100 -ar 48000 \"${outputfile}\""
    ffmpeg -y -i "${fname}" -c:v libx264 -crf 23 -profile:v high -r 30 -c:a aac -q:a 100 -ar 48000 "${outputfile}"

}

convert_avi_to_mp4() {
    fname="${1}"
    outputfile="$(python -c "import pathlib;print(pathlib.Path('$fname').stem)").mp4"
    echo $fname
    echo $outputfile
    echo "[running] ffmpeg -y -hide_banner -loglevel warning -i \"${fname}\" -vcodec libx264 -vprofile high -crf 28 \"${outputfile}\""
    ffmpeg -y -hide_banner -loglevel warning -i "${fname}" -vcodec libx264 -vprofile high -crf 28 "${outputfile}"
}


function gh_clone_structured() {
    gh repo clone "$1" "$(echo $1 | gsed 's/\// /g' | xargs -n 2 echo | gsed 's/ /\//')"
}

ps_kill() {
  local pid
  pid=$(ps aux |
    ggrep -i "$1" |
    ggrep -v ggrep |
    fzf --height 40% \
        --reverse \
        --header='Select process to kill' \
        --preview 'echo {}' \
        --preview-window up:3:wrap \
        --layout=reverse-list \
        --inline-info \
        --border \
        | gawk '{print $2}')
  if [ -n "$pid" ]; then
    echo "Killing process $pid"
    kill -9 "$pid"
  else
    echo "No process selected"
  fi
}

function download_docs() {
    # Function to download HTML documentation using wget
    # Usage: download_docs URL [OUTPUT_DIR]
    # Example: download_docs https://docs.marimo.io/genindex.html custom_docs

    # Check if URL parameter is provided
    if [[ -z "$1" ]]; then
        echo "Error: URL parameter is required"
        echo "Usage: download_docs URL [OUTPUT_DIR]"
        return 1
    fi

    local url="$1"
    local output_dir="${2:-rtdocs}"  # Use second parameter if provided, otherwise default to 'rtdocs'
    local original_dir="$PWD"

    # Check if ~/Documents/ai_docs exists
    if [[ ! -d "$HOME/Documents/ai_docs" ]]; then
        echo "Error: Directory ~/Documents/ai_docs does not exist"
        return 1
    fi

    # Change to the target directory
    cd "$HOME/Documents/ai_docs" || return 1

    # Run wget command
    wget -r -A.html -P "$output_dir" "$url"
    local wget_status=$?

    # Return to original directory
    cd "$original_dir" || return 1

    # Check if wget was successful
    if [[ $wget_status -eq 0 ]]; then
        echo "Documentation downloaded successfully to ~/Documents/ai_docs/$output_dir"
        return 0
    else
        echo "Failed to download documentation"
        return 1
    fi
}



determine_commands() {
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        if command -v gsed >/dev/null 2>&1; then
            SED="gsed"
        else
            SED="sed"
        fi
        if command -v ggrep >/dev/null 2>&1; then
            GREP="ggrep"
        else
            GREP="grep"
        fi
    else
        # Linux
        SED="sed"
        GREP="grep"
    fi
}

generate_exclude_patterns() {
    gitignore_file="$1"
    exclude_patterns=""

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] || [ "${line#\#}" != "$line" ] && continue
        [ "${line#!}" != "$line" ] && continue

        line=$(printf '%s\n' "$line" | $SED -e 's/[]\[\*\?]/\\&/g')
        exclude_patterns="$exclude_patterns --exclude '$line'"

        # Generate additional patterns for directories
        case "$line" in
            */)
                exclude_patterns="$exclude_patterns --exclude '$line**'"
                ;;
            *)
                if [ -d "$line" ]; then
                    exclude_patterns="$exclude_patterns --exclude '$line/**'"
                fi
                ;;
        esac
    done < "$gitignore_file"

    # Add specific patterns for .ruff_cache
    exclude_patterns="$exclude_patterns --exclude '.ruff_cache/**'"

    printf '%s' "$exclude_patterns"
}


select_and_process_files() {
    determine_commands
    printf "Enter the output file path: "
    read -r output_file

    gitignore_file=".gitignore"
    exclude_patterns=$(generate_exclude_patterns "$gitignore_file")

    eval "fd --type f --hidden --no-ignore-vcs $exclude_patterns" | \
    fzf -m | \
    xargs -I {} files-to-prompt {} --cxml -o "$output_file"
}


download_docs_backoff() {
    # Function to download HTML documentation using wget with exponential backoff
    # Usage: download_docs URL [OUTPUT_DIR]
    # Example: download_docs https://docs.marimo.io/genindex.html custom_docs

    if [ -z "$1" ]; then
        echo "Error: URL parameter is required"
        echo "Usage: download_docs URL [OUTPUT_DIR]"
        return 1
    fi

    url="$1"
    output_dir="${2:-rtdocs}"
    original_dir="$PWD"
    max_attempts=5
    base_wait=5

    if [ ! -d "$HOME/Documents/ai_docs" ]; then
        echo "Error: Directory ~/Documents/ai_docs does not exist"
        return 1
    fi

    cd "$HOME/Documents/ai_docs" || return 1

    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        echo "Attempt $attempt of $max_attempts"

        wget -c -r -A.html -P "$output_dir" --wait=1 --random-wait "$url"
        wget_status=$?

        if [ $wget_status -eq 0 ]; then
            echo "Documentation downloaded successfully to ~/Documents/ai_docs/$output_dir"
            cd "$original_dir" || return 1
            return 0
        elif [ $wget_status -eq 8 ]; then
            echo "Server error encountered. Retrying..."
            wait_time=$((base_wait * 2 ** (attempt - 1)))
            echo "Waiting for $wait_time seconds before next attempt"
            sleep $wait_time
        else
            echo "Failed to download documentation. Error code: $wget_status"
            cd "$original_dir" || return 1
            return 1
        fi
    done

    echo "Max attempts reached. Failed to download documentation."
    cd "$original_dir" || return 1
    return 1
}

# escape single quotes for use in shell scripts
escape_single_quotes() {
    echo "$1" | gsed "s/'/'\\\\''/g"
}

process_and_move_files() {
    local extension="${1:-mp4}"
    local target_dir="${2:-/Users/malcolm/Downloads/gallery-dl/mp4s}"

    local OIFS="$IFS"
    IFS=$'\n'

    # Clear existing files
    rm run_cp.sh run_rm.sh || true
    touch run_cp.sh run_rm.sh || true
    chmod +x run_cp.sh run_rm.sh || true

    # Write the header and redirection setup to both scripts
    cat << 'EOF' | tee run_cp.sh run_rm.sh > /dev/null
#!/usr/bin/env zsh
set -e

# Redirect stdout to /dev/null, keep stderr
exec 1>/dev/null

# Trap to restore stdout on exit
trap 'exec 1>&3' EXIT

# Save original stdout
exec 3>&1

OIFS="$IFS"
IFS=$'\n'

ulimit -n 65536
ulimit -a
EOF

    local count=0
    local total=$(find . -maxdepth 1 -type f \( -name "*.$extension" -o -name "*.$extension*" \) | wc -l)

    for i in *."$extension" *."$extension"*; do
        if [[ -f "$i" ]]; then
            ((count++))
            local escaped_filename=$(escape_single_quotes "$i")
            if [ $count -eq $total ]; then
                echo "cp -av -- '${escaped_filename}' '$target_dir'" >> run_cp.sh
                echo "trash -- '${escaped_filename}'" >> run_rm.sh
            else
                echo "cp -av -- '${escaped_filename}' '$target_dir' && \\" >> run_cp.sh
                echo "trash -- '${escaped_filename}' && \\" >> run_rm.sh
            fi
        fi
    done

    # Write the footer to both scripts
    cat << 'EOF' | tee -a run_cp.sh run_rm.sh > /dev/null
echo 'done' >&2
IFS="$OIFS"
EOF

    echo -e "\n========== Contents of run_cp.sh ==========\n"
    cat run_cp.sh
    echo -e "\n========== Contents of run_rm.sh ==========\n"
    cat run_rm.sh
    echo -e "\nCommands have been written to run_cp.sh and run_rm.sh"

    # Prompt user to run the copy script
    printf "Do you want to run the copy script now? (y/n): "
    read -r user_input
    user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
    if [[ "$user_input" =~ ^(yes|y)$ ]]; then
        echo "Running ./run_cp.sh"
        ./run_cp.sh
    else
        echo "Not running the script."
        echo "To run the copy script later, use: ./run_cp.sh"
        echo "To run the remove script later, use: ./run_rm.sh"
    fi

    IFS="$OIFS"
}


# # 1. With automatic destination mapping
# lms_sync -s "/Users/malcolm/Downloads/gallery-dl/artstation"

# # 2. With explicit destination (overrides automatic mapping)
# lms_sync -s "/Users/malcolm/Downloads/gallery-dl/artstation" -d "/custom/backup/path"

# # 3. With automatic mapping and no confirmation
# lms_sync -s "/Users/malcolm/Downloads/gallery-dl/artstation" -y

# Color setup for the terminal
setup_colors() {
    # Only setup colors if connected to a terminal
    if [ -t 1 ]; then
        # Reset
        RESET='\033[0m'

        # Regular Colors
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        RED='\033[0;31m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'

        # Bold Colors
        BOLD_GREEN='\033[1;32m'
        BOLD_YELLOW='\033[1;33m'
        BOLD_RED='\033[1;31m'
        BOLD_BLUE='\033[1;34m'
        BOLD_CYAN='\033[1;36m'
    else
        # No colors if not in a terminal
        RESET=''
        GREEN=''
        YELLOW=''
        RED=''
        BLUE=''
        CYAN=''
        BOLD_GREEN=''
        BOLD_YELLOW=''
        BOLD_RED=''
        BOLD_BLUE=''
        BOLD_CYAN=''
    fi
}

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${RESET} $*" >&2
}

log_success() {
    echo -e "${BOLD_GREEN}[SUCCESS]${RESET} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${RESET} $*" >&2
}

log_error() {
    echo -e "${BOLD_RED}[ERROR]${RESET} $*" >&2
}

log_prompt() {
    echo -e "${BOLD_BLUE}[PROMPT]${RESET} $*" >&2
}

log_cmd() {
    echo -e "${CYAN}[CMD]${RESET} $*" >&2
}

lms_sync() {
    ulimit -n 65536
    OIFS="$IFS"
    IFS=$'\n'

    # Setup colors
    setup_colors

    setup_commands() {
        # Initialize command check status
        local cmd_check_failed=0

        # Initialize commands as empty
        GREP=""
        AWK=""
        SED=""
        STAT=""
        DF=""
        DU=""

        # Detect OS
        local os_type
        os_type="$(uname -s)"

        if [ "$os_type" = "Darwin" ]; then
            # On macOS, prefer GNU versions if available
            if command -v ggrep >/dev/null 2>&1; then
                GREP="ggrep"
            elif command -v grep >/dev/null 2>&1; then
                log_warn "ggrep not found, using BSD grep. Some features might not work correctly."
                log_warn "Hint: Install GNU grep with 'brew install grep'"
                GREP="grep"
                cmd_check_failed=1
            else
                log_error "Neither ggrep nor grep found"
                return 1
            fi

            if command -v gawk >/dev/null 2>&1; then
                AWK="gawk"
            elif command -v awk >/dev/null 2>&1; then
                log_warn "gawk not found, using BSD awk. Some features might not work correctly."
                log_warn "Hint: Install GNU awk with 'brew install gawk'"
                AWK="awk"
                cmd_check_failed=1
            else
                log_error "Neither gawk nor awk found"
                return 1
            fi

            if command -v gsed >/dev/null 2>&1; then
                SED="gsed"
            elif command -v sed >/dev/null 2>&1; then
                log_warn "gsed not found, using BSD sed. Some features might not work correctly."
                log_warn "Hint: Install GNU sed with 'brew install gnu-sed'"
                SED="sed"
                cmd_check_failed=1
            else
                log_error "Neither gsed nor sed found"
                return 1
            fi

            if command -v gdf >/dev/null 2>&1; then
                DF="gdf"
            elif command -v df >/dev/null 2>&1; then
                log_warn "gdf not found, using BSD df. Some features might not work correctly."
                log_warn "Hint: Install GNU df with 'brew install coreutils'"
                DF="df"
                cmd_check_failed=1
            else
                log_error "Neither gdf nor df found"
                return 1
            fi

            if command -v gdu >/dev/null 2>&1; then
                DU="gdu"
            elif command -v du >/dev/null 2>&1; then
                log_warn "gdu not found, using BSD du. Some features might not work correctly."
                log_warn "Hint: Install GNU du with 'brew install coreutils'"
                DU="du"
                cmd_check_failed=1
            else
                log_error "Neither gdu nor du found"
                return 1
            fi
        else
            # On Linux, use standard GNU versions
            GREP="grep"
            AWK="awk"
            SED="sed"
            STAT="stat"
            DF="df"
            DU="du"
        fi

        # Add summary if any commands were missing
        if [ "$cmd_check_failed" -eq 1 ]; then
            echo "" >&2
            log_warn "Some GNU utilities were not found. For best results, install them with:"
            echo -e "${CYAN}brew install coreutils grep gnu-sed gawk${RESET}" >&2
            echo "" >&2
        fi

        # Export for use in subshells
        export GREP AWK SED STAT DF DU
    }

    local source=""
    local dest=""
    local skip_confirm=0
    # Default backup prefix - can be changed as needed
    local BACKUP_PREFIX="/Volumes/elements4tb2022/backups/silicontop"
    local SOURCE_PREFIX="/Users/malcolm"

    # Create detailed help message with colors
    local help_msg="${BOLD_BLUE}lms_sync${RESET} - Wrapper for lms sync with path mapping

${BOLD_CYAN}Usage:${RESET} lms_sync [OPTIONS]

${BOLD_CYAN}Options:${RESET}
    ${GREEN}-s, --source${RESET} <path>     Source directory path (required)
    ${GREEN}-d, --dest${RESET} <path>       Destination directory path (optional)
                           If not provided, automatically mapped from source:
                           $SOURCE_PREFIX/path/to/dir → $BACKUP_PREFIX/path/to/dir
    ${GREEN}-y, --yes${RESET}              Skip confirmation prompt
    ${GREEN}-h, --help${RESET}             Display this help message

${BOLD_CYAN}Examples:${RESET}
    # With automatic destination mapping:
    lms_sync -s \"$SOURCE_PREFIX/Downloads/gallery-dl/artstation\"

    # With explicit destination:
    lms_sync -s \"$SOURCE_PREFIX/Downloads/gallery-dl/artstation\" -d \"/custom/backup/path\"

    # Skip confirmation:
    lms_sync -s \"$SOURCE_PREFIX/Downloads/gallery-dl/artstation\" -y

${BOLD_CYAN}Notes:${RESET}
    - Source path must exist and be readable
    - Destination parent directory must exist and be writable
    - Uses --nodelete and --secure flags with lms sync
    - Automatically detects and uses GNU utilities on macOS if available"

    local usage="Usage: lms_sync [-s|--source <source>] [-d|--dest <destination>] [-y|--yes] [-h|--help]"

    # Display help if no arguments provided
    if [ $# -eq 0 ]; then
        echo -e "$help_msg" >&2
        IFS="$OIFS"
        return 1
    fi

    # Check if lms command exists
    if ! command -v lms >/dev/null 2>&1; then
        log_error "'lms' command not found. Please ensure it's installed and in your PATH"
        IFS="$OIFS"
        return 1
    fi

    # Setup commands
    setup_commands || {
        IFS="$OIFS"
        return 1
    }

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo -e "$help_msg" >&2
                IFS="$OIFS"
                return 0
                ;;
            -s|--source)
                if [ -n "$2" ]; then
                    source="$2"
                    shift 2
                else
                    log_error "Source argument is missing"
                    echo -e "$usage" >&2
                    IFS="$OIFS"
                    return 1
                fi
                ;;
            -d|--dest)
                if [ -n "$2" ]; then
                    dest="$2"
                    shift 2
                else
                    log_error "Destination argument is missing"
                    echo -e "$usage" >&2
                    IFS="$OIFS"
                    return 1
                fi
                ;;
            -y|--yes)
                skip_confirm=1
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                echo -e "Try 'lms_sync --help' for more information." >&2
                IFS="$OIFS"
                return 1
                ;;
        esac
    done

    # Check if source is provided
    if [ -z "$source" ]; then
        log_error "Source is required"
        echo -e "Try 'lms_sync --help' for more information." >&2
        IFS="$OIFS"
        return 1
    fi

    # If destination is not provided, derive it from source
    if [ -z "$dest" ]; then
        # Check if source starts with SOURCE_PREFIX
        if ! "$GREP" -q "^$SOURCE_PREFIX" <<< "$source"; then
            log_error "Source path must start with $SOURCE_PREFIX when using automatic destination mapping"
            IFS="$OIFS"
            return 1
        fi

        # Replace SOURCE_PREFIX with BACKUP_PREFIX to create destination path
        dest="$($SED "s|^$SOURCE_PREFIX|$BACKUP_PREFIX|" <<< "$source")"
        log_info "Using derived destination path: $dest"
    fi

    # Validation checks
    if [ ! -e "$source" ]; then
        log_error "Source '$source' does not exist"
        IFS="$OIFS"
        return 1
    fi

    if [ ! -r "$source" ]; then
        log_error "Source '$source' is not readable"
        IFS="$OIFS"
        return 1
    fi

    if [ ! -d "$source" ]; then
        log_error "Source '$source' is not a directory"
        IFS="$OIFS"
        return 1
    fi

    dest_parent="$(dirname "$dest")"
    if [ ! -d "$dest_parent" ]; then
        log_error "Destination parent directory '$dest_parent' does not exist"
        IFS="$OIFS"
        return 1
    fi

    if [ ! -w "$dest_parent" ]; then
        log_error "Destination parent directory '$dest_parent' is not writable"
        IFS="$OIFS"
        return 1
    fi

    if [ -e "$dest" ]; then
        if [ ! -d "$dest" ]; then
            log_error "Destination '$dest' exists but is not a directory"
            IFS="$OIFS"
            return 1
        fi
        if [ ! -w "$dest" ]; then
            log_error "Destination '$dest' exists but is not writable"
            IFS="$OIFS"
            return 1
        fi
    fi

    # Check disk space
    if [ -d "$dest" ]; then
        source_size=$("$DU" -s "$source" 2>/dev/null | "$AWK" '{print $1}')
        dest_free=$("$DF" -P "$dest" 2>/dev/null | "$AWK" 'NR==2 {print $4}')

        if [ -n "$source_size" ] && [ -n "$dest_free" ]; then
            if [ "$source_size" -gt "$dest_free" ]; then
                log_warn "Destination may not have enough free space"
                log_warn "Source size: $(($source_size / 1024)) MB"
                log_warn "Destination free space: $(($dest_free / 1024)) MB"
                if [ "$skip_confirm" -eq 1 ]; then
                    log_warn "Continuing anyway due to --yes flag..."
                else
                    log_prompt "Do you want to continue anyway? (y/N) "
                    read -r space_answer
                    case "$space_answer" in
                        [Yy]*)
                            log_info "Continuing..."
                            ;;
                        *)
                            log_info "Operation cancelled"
                            IFS="$OIFS"
                            return 1
                            ;;
                    esac
                fi
            fi
        else
            log_warn "Unable to check available disk space"
        fi
    fi

    # Construct the command
    local cmd="lms sync --nodelete --secure \"$source\" \"$dest\""

    # Handle confirmation
    if [ "$skip_confirm" -eq 1 ]; then
        log_cmd "Executing command: $cmd"
    else
        log_prompt "About to execute command:"
        log_cmd "$cmd"
        log_prompt "Do you want to continue? (y/N) "
        read -r answer
        case "$answer" in
            [Yy]*)
                log_info "Executing command..."
                ;;
            *)
                log_info "Operation cancelled"
                IFS="$OIFS"
                return 1
                ;;
        esac
    fi

    # Create trap to restore IFS in case of interrupt
    trap 'log_error "Operation interrupted"; IFS="$OIFS"; return 1' INT TERM

    # Execute the command
    eval "$cmd"
    local cmd_status=$?

    # Remove trap
    trap - INT TERM

    if [ $cmd_status -eq 0 ]; then
        log_success "Sync completed successfully"
    else
        log_error "Sync failed with exit code $cmd_status"
    fi

    log_info "Done"
    IFS="$OIFS"
    return $cmd_status
}

dl_thumb_only() {
    pyenv activate yt-dlp3 || true
    echo " [running] yt-dlp -n --ignore-errors --restrict-filenames --skip-download --write-thumbnail --convert-thumbnails png --cookies=~/Downloads/yt-cookies.txt ${1}"
    yt-dlp -n --ignore-errors --restrict-filenames --skip-download --write-thumbnail --convert-thumbnails png --cookies=~/Downloads/yt-cookies.txt "${1}"
}

alias dto='dl_thumb_only'



copy_to_large_and_small_folders(){
    local fname="${1}"
    echo "$fname"
    mkdir -p large/ small/
    gfind "${fname}" -type f \( \
        -iname "*.jpg"  -o \
        -iname "*.jpeg" -o \
        -iname "*.png"  -o \
        -iname "*.gif"  -o \
        -iname "*.bmp"  -o \
        -iname "*.tiff" -o \
        -iname "*.webp" -o \
        -iname "*.mp4"  -o \
        -iname "*.mov"  -o \
        -iname "*.avi"  -o \
        -iname "*.mkv"  -o \
        -iname "*.flv"  -o \
        -iname "*.wmv" \) \
        -exec sh -c 'cp -- "$0" large/ && cp -- "$0" small/' {} \;
}

prepare_for_ig_story() {
    local input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    local output_file="$(python -c "import pathlib;print(pathlib.Path('${1}').stem)")_ig_story.mp4"
    local get_timestamp=$(gstat -c %y "${input_file}")
    local bg_color

    echo -e "Input file: ${input_file}"
    echo -e "Output file: ${output_file}"

    # Sample color from top-left pixel (0,0) of the first frame
    bg_color=$(ffmpeg -i "${input_file}" -vf "crop=1:1:0:0,boxblur=luma_radius=0:chroma_radius=0:alpha_radius=0" -frames:v 1 -f rawvideo -pix_fmt rgb24 pipe:1 | xxd -p -c 3 | sed 's/$/ff/' | sed 's/^/0x/')

    # If color sampling fails, use black
    if [ -z "$bg_color" ]; then
        bg_color="0x000000"
    fi

    echo "Using background color: $bg_color"

    time ffmpeg -y \
    -hide_banner -loglevel warning \
    -i "${input_file}" \
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
    -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=${bg_color}" \
    -c:a aac \
    -ar 44100 \
    -ac 2 \
    "${output_file}"

    gtouch -d "$get_timestamp" "${output_file}"
}

image_prepare_for_ig_reel() {
    local full_path_input_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}{p.suffix}\")")"
    local full_path_output_file="$(python -c "import pathlib;p=pathlib.Path('${1}');print(f\"{p.stem}_ig_story{p.suffix}\")")"
    local primary_color=$(magick "${full_path_input_file}" -format "%[hex:p{0,0}]" info:)
    local get_timestamp=$(gstat -c %y "${full_path_input_file}")

    echo -e "Input file: ${full_path_input_file}"
    echo -e "Output file: ${full_path_output_file}"
    echo -e "Primary color: ${primary_color}"

    # Instagram Reel dimensions: 1080x1920
    magick "${full_path_input_file}" \
        -resize 1080x1920^ \
        -gravity center \
        -extent 1080x1920 \
        -background "#${primary_color}" \
        -compose Copy \
        -quality 95 \
        "${full_path_output_file}"

    gtouch -d "$get_timestamp" "${full_path_output_file}"
}


prepare_images_story() {
    fd -a --max-depth=1 --ignore -p -e jpg -e png -e jpeg --exclude '*_ig_reel*' --exclude '*_ig_story*' --exclude '*smaller*' --exclude '*larger*' -x zsh -ic 'image_prepare_for_ig_reel "$1"' zsh
}

prepare_videos_story() {
    fd -a --max-depth=1 --ignore -p -e mp4 --exclude '*_ig_reel*' --exclude '*_ig_story*' --exclude '*smaller*' --exclude '*larger*' -x zsh -ic 'prepare_for_ig_story "$1"' zsh
}

prepare_all_story() {
    prepare_images_story
    prepare_videos_story
}


prepare_everything_story(){
    ulimit -n 65536
    prepare_gif
    unzip_rm
    json_rm
    webp_to_jpg
    heic_to_jpg
    prepare_mov_to_mp4
    prepare_all_story
    prepare_orig
}

add_text_to_ig_video() {
    local input_file="$1"
    local text="$2"
    local output_file="${input_file%.*}_with_text.mp4"
    local font_file="/System/Library/Fonts/Supplemental/Arial.ttf"
    local font_size=50
    local padding=20  # Space between text and video content

    # Get video dimensions
    local video_info=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=width,height -of csv=p=0 "$input_file")
    local width=$(echo $video_info | cut -d',' -f1)
    local height=$(echo $video_info | cut -d',' -f2)

    # Calculate text position above video content
    local text_y=$((height * 1/4))  # Position text in top quarter
    local box_height=$((font_size + padding))

    ffmpeg -i "$input_file" \
        -vf "drawbox=x=0:y=$((text_y - padding/2)):w=iw:h=${box_height}:color=black@0.5:t=fill,
             drawtext=fontfile='${font_file}':fontsize=${font_size}:fontcolor=white:box=0:boxcolor=black@0.5:
                      x=(w-tw)/2:y=${text_y}+(th/${padding}):text='${text}'" \
        -c:a copy \
        "${output_file}"

    echo "Video with text created: $output_file"
}


# Function to extract Twitter handles from images in a directory recursively
extract_twitter_handles() {
  local dir="$1"
  local output_file="extracted_handles.txt"

  # Ensure the output file is empty before starting
  > "$output_file"

  # Ensure Tesseract is installed
  if ! command -v tesseract >/dev/null 2>&1; then
    echo "Error: Tesseract is not installed. Install it using Homebrew: brew install tesseract"
    return 1
  fi

  # Find and process image files recursively
  find "$dir" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.bmp' -o -iname '*.tiff' \) | while read -r image_path; do
    # Perform OCR on the image and extract text
    text=$(tesseract "$image_path" - -l eng 2>/dev/null)

    # Use grep with regex to find Twitter handles (e.g., @username)
    echo "$text" | grep -oE '@[a-zA-Z0-9_]+' | while read -r handle; do
      # Prefix the handle with https://x.com/ and save it to the output file
      url="https://x.com/${handle#@}"
      echo "$image_path: $url" >> "$output_file"
      echo "Extracted: $url from $image_path"
    done
  done

  echo "Extraction complete. Results saved to '$output_file'."
}


dl_helldivers() {
    local uri="$1"
    pyenv activate yt-dlp3 || true
    echo " [running] yt-dlp -v -f 299+bestaudio -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg "$uri""
    yt-dlp -v -f 299+bestaudio -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --cookies=~/Downloads/yt-cookies.txt --convert-thumbnails jpg "$uri"
}

alias dlh='dl_helldivers'

alias cn='cursor-nightly'

dl_using_chrome(){
    local uri="$1"
    local profile_name="${2:-2}"  # Default to 2 if not provided

    pyenv activate yt-dlp3 || true
    yt-dlp -I "1::2" --cookies-from-browser chrome:Profile\ $profile_name "$uri"

}
alias dlc='dl_using_chrome'

# ---------------------------------------------------------
# chezmoi managed - end.zsh
# ---------------------------------------------------------
