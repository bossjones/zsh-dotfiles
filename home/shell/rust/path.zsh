
if [[ "$OSTYPE" == darwin* ]]
then
    _ARCH=$(uname -m)
    # PASS FOR NOW
else
    if [ -d "${HOME}/.cargo" ]
    then
        . "$HOME/.cargo/env"
    fi
fi