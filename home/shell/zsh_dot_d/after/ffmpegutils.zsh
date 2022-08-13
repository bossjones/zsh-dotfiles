function crop_yt_tiktoks() {
    local _input=$(basename -- "${1}" | cut -d"." -f1)
    local get_extension=$(basename -- $1 | cut -d"." -f2)
    local _input_fname="${_input}.${get_extension}"
    local _out_fname="${_input}_out.${get_extension}"

    echo "_input = $_input"
    echo "get_extension = $get_extension"
    echo "_input_fname = $_input_fname"
    echo "_out_fname = $_out_fname"

    echo "ffmpeg -y -i \"${_input_fname}\" -filter:v \"crop=403:720:441:436:keep_aspect=1\" -c:a copy \"${_out_fname}\""

    ffmpeg -y -i "${_input_fname}" -filter:v "crop=403:720:441:436:keep_aspect=1" -c:a copy "${_out_fname}"
}


# https://gist.github.com/jonsuh/3c89c004888dfc7352be
# ----------------------------------
# Colors
# ----------------------------------
export NOCOLOR='\033[0m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export ORANGE='\033[0;33m'
export BLUE='\033[0;34m'
export MAD_BLUE='\e[34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHTGRAY='\033[0;37m'
export DARKGRAY='\033[1;30m'
export LIGHTRED='\033[1;31m'
export LIGHTGREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export LIGHTBLUE='\033[1;34m'
export LIGHTPURPLE='\033[1;35m'
export LIGHTCYAN='\033[1;36m'
export WHITE='\033[1;37m'

get_loop_commands() {
    rm loop.txt || true
    for filename in ./*.mp4; do echo ffmpeg-loop \"$filename\"; done > loop.txt
    cat loop.txt
}

ffmpeg-generate-ig-square() {
    rm -fv square.txt
    touch square.txt
    [ "$(ls *.jpg | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*jpg*; do echo ffmpeg -hide_banner -loglevel warning -i "$filename" -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=white,setdar=1:1" "ig-square-1080x1080-$(basename -- "${filename}")"; done >> square.txt
    [ "$(ls *.jpeg | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*jpeg*; do echo ffmpeg -hide_banner -loglevel warning -i "$filename" -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=white,setdar=1:1" "ig-square-1080x1080-$(basename -- "${filename}")"; done >> square.txt
    [ "$(ls *.png | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*png*; do echo ffmpeg -hide_banner -loglevel warning -i "$filename" -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=white,setdar=1:1" "ig-square-1080x1080-$(basename -- "${filename}")"; done >> square.txt
    cat square.txt
    bash square.txt
    rm square.txt
}

ffmpeg-square-mp4() {
    OIFS="$IFS"
    IFS=$'\n'
    rm -fv square.txt
    touch square.txt
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo ffmpeg -hide_banner -loglevel warning -i "${filename}" -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=white,setdar=1:1" "ig-square-1080x1080-$(basename -- "${filename}")"; done >> square.txt
    cat square.txt
    bash square.txt
    rm square.txt
    IFS="$OIFS"
}
# $(PWD)/

ffmpeg-crop-story-batch() {
    OIFS="$IFS"
    IFS=$'\n'
    rm -fv story.txt
    touch story.txt
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo ffmpeg-crop-story "${filename}"; done >> story.txt
    cat story.txt
    bash story.txt
    rm story.txt
    IFS="$OIFS"
}
# $(PWD)/

ffmpeg-mov-to-mp4() {
    OIFS="$IFS"
    IFS=$'\n'
    rm -fv square.txt || true
    touch square.txt
    current_dir=$(PWD)

    [ "$(ls *.MOV | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*MOV*; do echo ffmpeg-mov-to-mp4 $(python3 -c "import pathlib;p=pathlib.Path('${filename}');print(p)"); done >> square.txt
    [ "$(ls *.mov | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mov*; do echo ffmpeg-mov-to-mp4 $(python3 -c "import pathlib;p=pathlib.Path('${filename}');print(p)"); done >> square.txt
    cat square.txt
    # bash square.txt
    rm square.txt || true
    IFS="$OIFS"
}
# $(PWD)/

ffmpeg-dimensions-mp4() {
    rm -fv loop.txt
    touch loop.txt


    OIFS="$IFS"
    IFS=$'\n'
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.mp4"`
    do
        echo "file = $file"
        echo ffmpeg-dimensions -f "$file" >> loop.txt
    done

    cat loop.txt
    gsed -i "s,\.\/,'\.\/,g" loop.txt
    gsed -i "s,$,',g" loop.txt
    cat loop.txt
    bash loop.txt >> dimensions_info.txt
    rm loop.txt
    sort -ru dimensions_info.txt > dimensions.txt

    cat dimensions.txt
    IFS="$OIFS"

}

ffmpeg-dimensions-jpeg() {
    rm -fv loop.txt
    touch loop.txt


    OIFS="$IFS"
    IFS=$'\n'
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.JPEG|*.jpeg|*.JPG|*.jpg"`
    do
        echo "file = $file"
        echo ffmpeg-dimensions -f "$file" >> loop.txt
    done

    cat loop.txt
    gsed -i "s,\.\/,'\.\/,g" loop.txt
    gsed -i "s,$,',g" loop.txt
    cat loop.txt
    bash loop.txt >> dimensions_info.txt
    rm loop.txt
    sort -ru dimensions_info.txt > dimensions.txt

    cat dimensions.txt
    IFS="$OIFS"
}

ffmpeg-dimensions-png() {
    rm -fv loop.txt
    touch loop.txt


    OIFS="$IFS"
    IFS=$'\n'
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.png"`
    do
        echo "file = $file"
        echo ffmpeg-dimensions -f "$file" >> loop.txt
    done

    cat loop.txt
    gsed -i "s,\.\/,'\.\/,g" loop.txt
    gsed -i "s,$,',g" loop.txt
    cat loop.txt
    bash loop.txt >> dimensions_info.txt
    rm loop.txt
    sort -ru dimensions_info.txt > dimensions.txt

    cat dimensions.txt
    IFS="$OIFS"
}

ffmpeg-dimensions-mov() {
    rm -fv loop.txt
    touch loop.txt


    OIFS="$IFS"
    IFS=$'\n'
    for file in `find . -maxdepth 1 -mindepth 1 -type f -name "*.MOV|*.mov"`
    do
        echo "file = $file"
        echo ffmpeg-dimensions -f "$file" >> loop.txt
    done

    cat loop.txt
    gsed -i "s,\.\/,'\.\/,g" loop.txt
    gsed -i "s,$,',g" loop.txt
    cat loop.txt
    bash loop.txt >> dimensions_info.txt
    rm loop.txt
    sort -ru dimensions_info.txt > dimensions.txt

    cat dimensions.txt
    IFS="$OIFS"
}

ffmpeg-loop-batch() {
    OIFS="$IFS"
    IFS=$'\n'
    rm -fv loop.txt
    touch loop.txt
    [ "$(ls *.mp4 | tr " " '\r' | wc -l | awk '{print $1}')" -gt "0" ] && for filename in ./*mp4*; do echo ffmpeg-loop-one "${filename}"; done >> loop.txt
    cat loop.txt
    bash loop.txt
    rm loop.txt
    IFS="$OIFS"
}


ffmpeg-dimensions-all() {
    rm all-dimensions.txt || true
    ffmpeg-dimensions-mp4 >> all-dimensions.txt
    ffmpeg-dimensions-jpeg >> all-dimensions.txt
    ffmpeg-dimensions-png >> all-dimensions.txt
    ffmpeg-dimensions-mov >> all-dimensions.txt
    grep -v "ffmpeg-dimensions" all-dimensions.txt >> temp.txt
    grep -v "file = ./" all-dimensions.txt >> temp.txt
    sort -ru temp.txt > all-dimensions.txt
    echo -e "\n\n ${GREEN}ffmpeg-dimensions-all]${NOCOLOR} ${CYAN}cat all-dimensions.txt${NOCOLOR}\n\n"
    cat all-dimensions.txt
}

function crop_yt_tiktoks() {
    local _input=$(basename -- "${1}" | cut -d"." -f1)
    local get_extension=$(basename -- $1 | cut -d"." -f2)
    local _input_fname="${_input}.${get_extension}"
    local _out_fname="${_input}_out.${get_extension}"

    echo "_input = $_input"
    echo "get_extension = $get_extension"
    echo "_input_fname = $_input_fname"
    echo "_out_fname = $_out_fname"

    echo "ffmpeg -y -i \"${_input_fname}\" -filter:v \"crop=403:720:441:436\" -c:a copy \"${_out_fname}\""

    ffmpeg -y -i "${_input_fname}" -filter:v "crop=403:720:441:436" -c:a copy "${_out_fname}"
}
