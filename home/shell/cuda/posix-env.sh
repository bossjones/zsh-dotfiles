# CUDA toolkit environment (POSIX; sourced by ~/.profile via /bin/sh and by
# ~/.bashrc). Inlined into home/compat.sh.tmpl and home/compat.bash.tmpl at
# chezmoi render time via the include function -- edit here, not there.
#
# Unlike the zsh module (home/shell/cuda/custom.zsh) this trusts only the
# update-alternatives-managed ${root}/cuda symlink, with no
# highest-version-on-disk fallback: POSIX sh cannot version-sort without a
# subprocess, and a lexical "last match" would pick cuda-9.0 over cuda-13.0.
# If the symlink is broken, sh/bash sessions get no CUDA env -- the right
# degradation for shells nobody does CUDA work in here.
#
# LD_LIBRARY_PATH intentionally not set; see custom.zsh for why.
if [ -d "${ZSH_DOTFILES_CUDA_ROOT:-/usr/local}/cuda/bin" ]; then
    CUDA_HOME="${ZSH_DOTFILES_CUDA_ROOT:-/usr/local}/cuda"
    CUDA_PATH="${CUDA_HOME}"
    export CUDA_HOME CUDA_PATH

    case ":${PATH}:" in
        *":${CUDA_HOME}/bin:"*) ;;
        *) PATH="${CUDA_HOME}/bin${PATH:+:${PATH}}"; export PATH ;;
    esac
fi
