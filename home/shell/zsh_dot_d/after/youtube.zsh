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
  echo " [running] youtube-dl -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt ${1}"
  youtube-dl -v -f best -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt ${1}
}

alias dl-thumb='yt-dl-thumb'

yt-dl-best-test () {
  echo " [running] youtube-dl -v -f \"bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio\" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt ${1}"
  youtube-dl -v -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt ${1}
}

yt-best () {
  echo " [running] youtube-dl -v -f \"bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio\" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json ${1}"
  youtube-dl -v -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio" -n --ignore-errors --restrict-filenames --write-thumbnail --no-mtime --embed-thumbnail --recode-video mp4 --cookies=~/Downloads/yt-cookies.txt --write-info-json ${1}
}

dl-split () {
  while IFS="" read -r p || [ -n "$p" ]; do
    yt-best $p
  done < download.txt
}

dl-safe () {
  pyenv activate ffmpeg-tools399 || true
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

prepare_from_square() {
  pyenv activate ffmpeg-tools399 || true
  ffmpeg-tools -c prepare-from-square -f "$(PWD)" -r
  find . -name "white.jpg" -exec rm -rfv {} \;
}
