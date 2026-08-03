# CUDA toolkit environment.
#
# Loaded immediately (not deferred) by [plugins.cuda], so it blocks the first
# prompt: zsh builtins and globbing only, no subprocesses.
#
# Version-agnostic on purpose. apt installs and purges toolkits under /usr/local
# without telling this file; the previous version pinned cuda-11.8 and went stale.
#   1. Prefer ${root}/cuda -- the update-alternatives-managed symlink.
#   2. Else the highest-numbered ${root}/cuda-<major>.<minor> still on disk.
#   3. Else do nothing at all.
#
# LD_LIBRARY_PATH is deliberately NOT set. ${root}/cuda-X/lib64 is a symlink to
# targets/x86_64-linux/lib, which the .deb packages already register via
# /etc/ld.so.conf.d/000_cuda.conf. Since LD_LIBRARY_PATH outranks the ldconfig
# cache, setting it only creates a way for a stale entry to shadow the correct
# libraries.
#
# ZSH_DOTFILES_CUDA_ROOT overrides the search prefix for testing only.

() {
    emulate -L zsh

    local root="${ZSH_DOTFILES_CUDA_ROOT:-/usr/local}"
    local cuda_home="" candidate
    local -a candidates

    if [[ -d "${root}/cuda/bin" ]]; then
        # -d follows the symlink, so a dangling ${root}/cuda fails this test.
        cuda_home="${root}/cuda"
    else
        # (N-/) silent when nothing matches; dirs and symlinks-to-dirs only.
        # (On)  reverse numeric sort, so 13.0 beats 9.0.
        # The <major>.<minor> shape skips the cuda-11 / cuda-12 alternatives
        # aliases, which are pointers to toolkits rather than toolkits.
        candidates=( ${root}/cuda-[0-9]*.[0-9]*(N-/) )
        for candidate in ${(On)candidates}; do
            [[ -d "${candidate}/bin" ]] && { cuda_home="$candidate"; break; }
        done
    fi

    [[ -n "$cuda_home" ]] || return 0

    export CUDA_HOME="$cuda_home"
    export CUDA_PATH="$cuda_home"   # CMake's FindCUDAToolkit looks for CUDA_PATH

    # Containment-guarded so a re-source cannot grow PATH. Preferred over
    # `typeset -U path`, which would dedupe PATH session-wide for every module
    # sheldon loads after this one.
    case ":${PATH}:" in
        *":${cuda_home}/bin:"*) ;;
        *) export PATH="${cuda_home}/bin:${PATH}" ;;
    esac
}
