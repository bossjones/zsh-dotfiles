# darktop config (8/10/2020)
if [[ "$OSTYPE" == darwin* ]]
then
  export PATH="$(brew --prefix unzip)/bin:$PATH"
fi

unzip_nuke() {
  unzip \*.zip && rm *.zip
}
