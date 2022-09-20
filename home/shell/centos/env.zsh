## On centos we need to custom compile A LOT of stuff, so tell the shell to use it all
_IS_CENTOS=$(\cat /etc/redhat-release | grep -i centos | wc -l)
if [[ "${_IS_CENTOS}" == "1" ]]
then
    export CC=$HOME/.gcc/10.2.0/bin/gcc
    export CXX=$HOME/.gcc/10.2.0/bin/g++
    export FC=$HOME/.gcc/10.2.0/bin/gfortran
    export LD_LIBRARY_PATH=$HOME/.gcc/10.2.0/lib64
    . "$HOME/.cargo/env"
fi
