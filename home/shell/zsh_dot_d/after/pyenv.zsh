
local OPT_HOMEBREW="/opt/homebrew"
if [[ -s "$OPT_HOMEBREW"/bin/brew ]]; then
    eval "$($OPT_HOMEBREW/bin/brew shellenv)"
fi

if [[ -s "$HOMEBREW_PREFIX"/opt/pyenv/libexec/pyenv ]]; then
  eval "$(${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv init --path)"
  eval "$(${HOMEBREW_PREFIX}/opt/pyenv/libexec/pyenv init -)"
  fpath=(${HOMEBREW_PREFIX}/opt/pyenv/completions $fpath)
  pyenv virtualenvwrapper_lazy

elif [[ -s "$HOME/.pyenv/bin/pyenv" ]]; then
  export PYENV_ROOT=~/.pyenv
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  pyenv virtualenvwrapper_lazy
fi

enable_openblas_flags() {
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/openblas/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/openblas/include"
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/openblas/lib/pkgconfig"
}

enable_compile_flags() {
  # SOURCE: https://github.com/jiansoung/issues-list/issues/13
  # Fixes: zipimport.ZipImportError: can't decompress data; zlib not available
  export LOCAL_HOMEBREW_PREFIX="$(brew --prefix)"
  export PATH="${LOCAL_HOMEBREW_PREFIX}/opt/tcl-tk/bin:$PATH"
  export PATH="${LOCAL_HOMEBREW_PREFIX}/opt/bzip2/bin:$PATH"
  export PATH="${LOCAL_HOMEBREW_PREFIX}/opt/ncurses/bin:$PATH"
  export PATH="${LOCAL_HOMEBREW_PREFIX}/opt/openssl@1.1/bin:$PATH"
  # SOURCE: https://github.com/jiansoung/issues-list/issues/13
  # Fixes: zipimport.ZipImportError: can't decompress data; zlib not available
  export CFLAGS="${CFLAGS} -I$(brew --prefix tcl-tk)/include"
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/tcl-tk/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/tcl-tk/include"
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/zlib/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/zlib/include"
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/sqlite/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/sqlite/include"
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/libffi/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/libffi/include"
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/bzip2/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/bzip2/include"
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/ncurses/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/ncurses/include"
  export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/openssl@1.1/lib"
  export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/openssl@1.1/include"
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/zlib/lib/pkgconfig"
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/sqlite/lib/pkgconfig"
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/tcl-tk/lib/pkgconfig"
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/libffi/lib/pkgconfig"
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/ncurses/lib/pkgconfig"
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/openssl@1.1/lib/pkgconfig"
  export PYTHON_CONFIGURE_OPTS="--with-tcltk-includes='-I$(brew --prefix tcl-tk)/include' --with-tcltk-libs='-L$(brew --prefix tcl-tk)/lib -ltcl8.6 -ltk8.6'"
  export PROFILE_TASK='-m test.regrtest --pgo \
        test_array \
        test_base64 \
        test_binascii \
        test_binhex \
        test_binop \
        test_bytes \
        test_c_locale_coercion \
        test_class \
        test_cmath \
        test_codecs \
        test_compile \
        test_complex \
        test_csv \
        test_decimal \
        test_dict \
        test_float \
        test_fstring \
        test_hashlib \
        test_io \
        test_iter \
        test_json \
        test_long \
        test_math \
        test_memoryview \
        test_pickle \
        test_re \
        test_set \
        test_slice \
        test_struct \
        test_threading \
        test_time \
        test_traceback \
        test_unicode \
  '
  
  if [[ -s "$(brew --prefix libsndfile)" ]]; then
    export CFLAGS="${CFLAGS} -I$(brew --prefix libsndfile)/include"
    export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/libsndfile/lib"
    export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/libsndfile/include"
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/libsndfile/lib/pkgconfig"
  fi

}

# enable_libsndfile_flags() {
#   export LOCAL_HOMEBREW_PREFIX="$(brew --prefix)"
#   export CFLAGS="${CFLAGS} -I$(brew --prefix libsndfile)/include"
#   export LDFLAGS="${LDFLAGS} -L${LOCAL_HOMEBREW_PREFIX}/opt/libsndfile/lib"
#   export CPPFLAGS="${CPPFLAGS} -I${LOCAL_HOMEBREW_PREFIX}/opt/libsndfile/include"
#   export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} ${LOCAL_HOMEBREW_PREFIX}/opt/libsndfile/lib/pkgconfig"
# }

print_compile_flags() {
  enable_compile_flags

  echo "----------------------"
  echo "Verify pyenv compile env vars"
  echo "----------------------"
  echo "LDFLAGS: ${LDFLAGS}"
  echo "CPPFLAGS: ${CPPFLAGS}"
  echo "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"
  echo "PYTHON VERSION TO COMPILE: ${_PY_VER_MAJOR}.${_PY_VER_MINOR}.${_PY_VER_MICRO}"
  echo "----------------------"
}

verify_keg_folders_exists() {
  stat "$(brew --prefix)/opt/tcl-tk/lib" && \
  stat "$(brew --prefix)/opt/zlib/lib" && \
  stat "$(brew --prefix)/opt/sqlite/lib" && \
  stat "$(brew --prefix)/opt/libffi/lib" && \
  stat "$(brew --prefix)/opt/bzip2/lib" && \
  stat "$(brew --prefix)/opt/ncurses/lib" && \
  stat "$(brew --prefix)/opt/openssl@1.1/lib" && \
  stat "$(brew --prefix)/opt/tcl-tk/include" && \
  stat "$(brew --prefix)/opt/zlib/include" && \
  stat "$(brew --prefix)/opt/sqlite/include" && \
  stat "$(brew --prefix)/opt/libffi/include" && \
  stat "$(brew --prefix)/opt/bzip2/include" && \
  stat "$(brew --prefix)/opt/ncurses/include" && \
  stat "$(brew --prefix)/opt/openssl@1.1/include" && \
  stat "$(brew --prefix)/opt/zlib/lib/pkgconfig" && \
  stat "$(brew --prefix)/opt/sqlite/lib/pkgconfig" && \
  stat "$(brew --prefix)/opt/tcl-tk/lib/pkgconfig" && \
  stat "$(brew --prefix)/opt/libffi/lib/pkgconfig" && \
  stat "$(brew --prefix)/opt/ncurses/lib/pkgconfig" && \
  stat "$(brew --prefix)/opt/openssl@1.1/lib/pkgconfig"

}

function compile_python() {
    if [ ! -d "${PYENV_ROOT}/versions/${_PY_VER_MAJOR}.${_PY_VER_MINOR}.${_PY_VER_MICRO}" ]; then
    # Control will enter here if $DIRECTORY exists.
    env PYTHON_CONFIGURE_OPTS="--enable-shared --enable-optimizations --enable-ipv6 --with-dtrace --enable-loadable-sqlite-extensions --with-openssl=${LOCAL_HOMEBREW_PREFIX}/opt/openssl@1.1" pyenv install -v ${_PY_VER_MAJOR}.${_PY_VER_MINOR}.${_PY_VER_MICRO}
    else
    echo " [python-compile](compile_python) python version ${_PY_VER_MAJOR}.${_PY_VER_MINOR}.${_PY_VER_MICRO} already installed, skipping"
    fi
}

python_interperter(){
  python3 -c "import sys;print(sys.executable)"
}


opencv-deps() {
  pip install scipy pillow
  pip install imutils h5py requests progressbar2
  pip install scikit-learn scikit-image
  pip install matplotlib
  mkdir ~/.matplotlib
  touch ~/.matplotlib/matplotlibrc
  echo "backend: TkAgg" >> ~/.matplotlib/matplotlibrc
  pip install tensorflow
  pip install keras
  python -c "import keras;"
  pip install scenedetect[opencv]
}