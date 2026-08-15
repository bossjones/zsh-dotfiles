## On centos we need to custom compile A LOT of stuff, so tell the shell to use it all
check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

if check_cmd rpm; then
    _IS_CENTOS=$(\cat /etc/redhat-release | grep -i centos | wc -l)
    if [[ "${_IS_CENTOS}" == "1" ]]
    then
        path+=($HOME/.gcc/10.2.0/bin)
    fi
fi
