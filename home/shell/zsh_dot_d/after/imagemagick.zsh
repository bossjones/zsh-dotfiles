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
