#!/usr/bin/env bash
# Verify the CUDA shell modules against REAL NVIDIA apt packages.
#
# Exercises home/shell/cuda/custom.zsh and home/shell/cuda/posix-env.sh against
# real NVIDIA packages, real update-alternatives, and real /etc/ld.so.conf.d.
# Nothing in CI covers this: CI runs on macOS only and the cuda sheldon plugin is
# Linux-gated, so this script is the actual gate for that code.
#
# No GPU required - the modules only inspect the filesystem. For driver/runtime
# compatibility checks, use scripts/cuda-verify-gpu.sh instead.
#
# Installs and purges real CUDA packages, so it refuses to run outside a
# container unless FORCE=1.
#
# Usage:
#   ./scripts/cuda-verify-config.sh                  # full matrix
#   ./scripts/cuda-verify-config.sh --help
#   DOTFILES_DIR=/mnt/x ./scripts/cuda-verify-config.sh
#   CUDA_SERIES=12-1 ./scripts/cuda-verify-config.sh
#
# Not `set -e`: every check should run so the result is a full matrix. apt steps
# are gated by must() instead, because a silently-failed install would make a
# later guard check pass vacuously.
set -uo pipefail

case "${1:-}" in
    -h | --help)
        sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
esac

DOTFILES_DIR="${DOTFILES_DIR:-/tmp/dotfiles}"
CUDA_SERIES="${CUDA_SERIES:-13-0}"
ZMOD="${DOTFILES_DIR}/home/shell/cuda/custom.zsh"
PMOD="${DOTFILES_DIR}/home/shell/cuda/posix-env.sh"
CLEANPATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

log_pass() {
    echo -e "  ${GREEN}PASS${RESET} $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}
log_fail() {
    echo -e "  ${RED}FAIL${RESET} $1"
    if [ -n "${2:-}" ]; then
        echo "       $2"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
}
log_note() { echo -e "  ${YELLOW}note${RESET} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${RESET}"; }

expect() {
    if [ "$2" = "$3" ]; then
        log_pass "$1"
    else
        log_fail "$1" "got [$2] want [$3]"
    fi
}

must() {
    if "$@" > /tmp/cuda-verify-apt.log 2>&1; then
        log_pass "apt: $*"
    else
        log_fail "apt: $*" "$(tail -4 /tmp/cuda-verify-apt.log)"
        echo -e "\n${RED}Aborting: later guard checks would pass vacuously.${RESET}"
        exit 1
    fi
}

# Space-separated list of existing paths matching a glob, without parsing ls.
list_paths() {
    local p
    local -a found=()
    for p in "$@"; do
        if [ -e "$p" ]; then
            found+=("$p")
        fi
    done
    if [ ${#found[@]} -eq 0 ]; then
        echo "(none)"
    else
        echo "${found[*]}"
    fi
}

# ---------------------------------------------------------------------------
# Guard rails
# ---------------------------------------------------------------------------
in_container() {
    [ -f /.dockerenv ] && return 0
    grep -qaE 'docker|containerd|lxc' /proc/1/cgroup 2>/dev/null && return 0
    return 1
}

if [ "${FORCE:-0}" != "1" ] && ! in_container; then
    echo -e "${RED}Refusing to run outside a container.${RESET}" >&2
    echo "This script installs and purges real CUDA packages." >&2
    echo "Use 'make smoke-cuda', or set FORCE=1 if you genuinely mean this." >&2
    exit 2
fi

for f in "$ZMOD" "$PMOD"; do
    if [ ! -r "$f" ]; then
        echo -e "${RED}Missing ${f}${RESET} - set DOTFILES_DIR?" >&2
        exit 2
    fi
done

# ---------------------------------------------------------------------------
# Probes. The zsh and POSIX programs live in files rather than inline quoted
# strings so the shell under test does the expansion, not this script.
# ---------------------------------------------------------------------------
PROBE_DIR="$(mktemp -d)"
trap 'rm -rf "$PROBE_DIR"' EXIT

cat > "${PROBE_DIR}/probe.zsh" << 'PROBE_ZSH'
source "$ZMOD"
source "$ZMOD"   # twice: proves PATH cannot grow on re-source
cuda_entries=${#${(M)${(s.:.)PATH}:#*cuda*}}
print -r -- "${CUDA_HOME:-NONE}|${cuda_entries}|${LD_LIBRARY_PATH:-NONE}"
PROBE_ZSH

cat > "${PROBE_DIR}/probe.sh" << 'PROBE_SH'
. "$PMOD"
. "$PMOD"
cuda_entries=$(printf %s "$PATH" | tr ":" "\n" | grep -c cuda)
printf "%s|%s|%s\n" "${CUDA_HOME:-NONE}" "$cuda_entries" "${LD_LIBRARY_PATH:-NONE}"
PROBE_SH

zprobe() {
    env -i PATH="$CLEANPATH" ZMOD="$ZMOD" zsh -f "${PROBE_DIR}/probe.zsh"
}
sprobe() {
    env -i PATH="$CLEANPATH" PMOD="$PMOD" "$1" "${PROBE_DIR}/probe.sh"
}

echo -e "${BLUE}CUDA shell-module verification${RESET}"
echo "  dotfiles : ${DOTFILES_DIR}"
echo "  series   : ${CUDA_SERIES}"

# ---------------------------------------------------------------------------
log_section "Stage 0 - nothing installed (the post-purge steady state)"
expect "zsh no-op" "$(zprobe)" "NONE|0|NONE"
expect "dash no-op" "$(sprobe dash)" "NONE|0|NONE"
expect "bash no-op" "$(sprobe bash)" "NONE|0|NONE"
rc_out=$(env -i ZMOD="$ZMOD" zsh -f "${PROBE_DIR}/probe.zsh" > /dev/null 2>&1; echo "rc=$?")
expect "zsh exits 0 with no diagnostics" "$rc_out" "rc=0"

# ---------------------------------------------------------------------------
log_section "Stage 1 - apt pin must beat NVIDIA's priority-600 repo pin"
if [ -r /etc/apt/preferences.d/cuda-repository-pin-600 ]; then
    log_note "cuda-keyring ships a 600 pin for 'release l=NVIDIA CUDA', above Ubuntu's 500"
    before=$(apt-cache policy nvidia-driver-580 2>/dev/null | awk '/Candidate:/{print $2}')
    cat > /etc/apt/preferences.d/99-nvidia-driver-from-ubuntu << 'PIN'
Package: nvidia-driver-* nvidia-dkms-* nvidia-kernel-common-* nvidia-kernel-source-* nvidia-utils-* nvidia-compute-utils-* nvidia-firmware-* xserver-xorg-video-nvidia-*
Pin: release o=NVIDIA
Pin-Priority: -1

Package: libnvidia-cfg1-* libnvidia-common-* libnvidia-compute-* libnvidia-decode-* libnvidia-encode-* libnvidia-extra-* libnvidia-fbc1-* libnvidia-gl-* libnvidia-egl-wayland* libxnvctrl*
Pin: release o=NVIDIA
Pin-Priority: -1
PIN
    after=$(apt-cache policy nvidia-driver-580 2>/dev/null | awk '/Candidate:/{print $2}')
    echo "  candidate without pin: ${before}"
    echo "  candidate with    pin: ${after}"

    case "$before" in
        *-1ubuntu1) log_pass "negative control: NVIDIA build wins without our pin (${before})" ;;
        *) log_fail "negative control" "expected an NVIDIA '-1ubuntu1' build, got '${before}'" ;;
    esac
    case "$after" in
        *ubuntu0.*) log_pass "pin holds: Ubuntu-archive build selected (${after})" ;;
        *) log_fail "pin did not hold" "got '${after}'" ;;
    esac

    # The narrow patterns must not collaterally block non-driver NVIDIA packages.
    # A naive 'nvidia-*' pattern blocks this one, which is how the bug was found.
    toolkit_cand=$(apt-cache policy nvidia-container-toolkit 2>/dev/null | awk '/Candidate:/{print $2}')
    if [ -n "$toolkit_cand" ] && [ "$toolkit_cand" != "(none)" ]; then
        log_pass "pin does not block nvidia-container-toolkit (${toolkit_cand})"
    else
        log_fail "pin is too broad" "nvidia-container-toolkit candidate is '${toolkit_cand:-empty}'"
    fi

    if apt-get install -s "cuda-toolkit-${CUDA_SERIES}" 2>/dev/null |
        grep -qE '^Inst (nvidia-driver|libnvidia-(cfg1|common|compute|decode|encode|extra|fbc1|gl)|xserver-xorg-video-nvidia)'; then
        log_fail "toolkit must pull no driver packages" "see: apt-get install -s cuda-toolkit-${CUDA_SERIES}"
    else
        log_pass "cuda-toolkit-${CUDA_SERIES} pulls zero driver packages"
    fi

    # The invariant that actually matters, and the one that caught two pin gaps
    # (libxnvctrl0, libnvidia-egl-wayland1) that the pattern list had missed.
    # See specs/cuda-toolkit-cleanup.md section 3.
    leak=$(apt-get -s upgrade 2>/dev/null |
        grep -cE '^Inst (nvidia-|libnvidia-|xserver-xorg-video-nvidia|libxnvctrl)')
    if [ "$leak" -eq 0 ]; then
        log_pass "no driver-stack package leaks through the pin on upgrade"
    else
        log_fail "pin leaks: ${leak} driver-stack package(s) would change" \
            "$(apt-get -s upgrade 2>/dev/null | grep -E '^Inst (nvidia-|libnvidia-|xserver|libxnvctrl)' | head -3)"
    fi
else
    log_note "no NVIDIA apt repo in this image - skipping pin checks"
fi

# ---------------------------------------------------------------------------
log_section "Stage 2 - real alternatives for two toolkits that have no bin/"
# config-common's postinst runs update-alternatives against these paths, so they
# must exist first; on a real host the content packages create them.
mkdir -p /usr/local/cuda-11.8 /usr/local/cuda-12.1
must apt-get install -y --no-install-recommends \
    cuda-toolkit-11-8-config-common cuda-toolkit-12-1-config-common
update-alternatives --display cuda 2>&1 | sed 's/^/    /'
echo "  /usr/local/cuda -> $(readlink -f /usr/local/cuda 2>/dev/null || echo '(absent)')"
expect "zsh rejects toolkits lacking bin/" "$(zprobe)" "NONE|0|NONE"
expect "dash rejects them too" "$(sprobe dash)" "NONE|0|NONE"

# ---------------------------------------------------------------------------
log_section "Stage 3 - install a real nvcc for series ${CUDA_SERIES}"
must apt-get install -y --no-install-recommends "cuda-nvcc-${CUDA_SERIES}"
update-alternatives --display cuda 2>&1 | sed 's/^/    /'
REAL_TOOLKIT="$(readlink -f /usr/local/cuda)"
echo "  resolved toolkit: ${REAL_TOOLKIT}"
expect "zsh prefers the alternatives-managed symlink" "$(zprobe)" "/usr/local/cuda|1|NONE"

cat > "${PROBE_DIR}/nvcc.zsh" << 'PROBE_NVCC'
source "$ZMOD"
nvcc --version 2>/dev/null | grep -o 'release [0-9.]*'
PROBE_NVCC
nvcc_ver=$(env -i PATH=/usr/bin:/bin ZMOD="$ZMOD" zsh -f "${PROBE_DIR}/nvcc.zsh")
if [ -n "$nvcc_ver" ]; then
    log_pass "nvcc reachable via the module's PATH (${nvcc_ver})"
else
    log_fail "nvcc not reachable via the module's PATH"
fi

# ---------------------------------------------------------------------------
log_section "Stage 3b - numeric ordering against real directories"
# Force the glob fallback with 9.0 present: a lexical sort ranks it above 13.0.
mv /usr/local/cuda /tmp/cuda-symlink-backup
mkdir -p /usr/local/cuda-9.0/bin
cp "${REAL_TOOLKIT}/bin/nvcc" /usr/local/cuda-9.0/bin/nvcc
echo "  candidates: $(list_paths /usr/local/cuda-*)"
expect "picks the highest real toolkit, not 9.0" "$(zprobe)" "${REAL_TOOLKIT}|1|NONE"
# Remove the fixture right away: apt purge will not clean up hand-made files, and
# leaving it would silently invalidate Stage 8's expectation.
rm -rf /usr/local/cuda-9.0

# ---------------------------------------------------------------------------
log_section "Stage 4 - cuda-NN major-version aliases must be ignored"
echo "  aliases present: $(list_paths /usr/local/cuda-[0-9] /usr/local/cuda-[0-9][0-9])"
alias_probe=$(zprobe)
case "$alias_probe" in
    /usr/local/cuda-[0-9]\|* | /usr/local/cuda-[0-9][0-9]\|*)
        log_fail "a major-version alias leaked into CUDA_HOME" "got [${alias_probe}]"
        ;;
    *)
        log_pass "major-version aliases excluded by the <major>.<minor> glob shape"
        ;;
esac
mv /tmp/cuda-symlink-backup /usr/local/cuda

# ---------------------------------------------------------------------------
log_section "Stage 5 - libraries resolve with LD_LIBRARY_PATH unset"
must apt-get install -y --no-install-recommends "cuda-cudart-${CUDA_SERIES}"
ldconfig
cudart_entries=$(ldconfig -p | grep -cE 'libcudart')
if [ "$cudart_entries" -gt 0 ]; then
    log_pass "ldconfig finds libcudart without LD_LIBRARY_PATH (${cudart_entries} entries)"
else
    log_fail "ldconfig found no libcudart" "dropping LD_LIBRARY_PATH would be unsafe"
fi
grep -rh . /etc/ld.so.conf.d/*cuda* 2>/dev/null | sed 's/^/    /'

# ---------------------------------------------------------------------------
log_section "Stage 6 - purge the two stale toolkits"
must apt-get purge -y cuda-toolkit-11-8-config-common cuda-toolkit-12-1-config-common
update-alternatives --display cuda 2>&1 | sed 's/^/    /'
expect "still resolves the remaining toolkit" "$(zprobe)" "/usr/local/cuda|1|NONE"

# ---------------------------------------------------------------------------
log_section "Stage 7 - dangling symlink (the mid-purge transient window)"
ln -sfn /usr/local/cuda-does-not-exist /usr/local/cuda
echo "  /usr/local/cuda -> $(readlink /usr/local/cuda) (target absent)"
expect "dangling symlink rejected, falls back to a real toolkit" "$(zprobe)" "${REAL_TOOLKIT}|1|NONE"
expect "POSIX snippet no-ops on a dangling symlink" "$(sprobe dash)" "NONE|0|NONE"

# ---------------------------------------------------------------------------
log_section "Stage 8 - purge everything CUDA"
apt-get purge -y '*cuda*' > /dev/null 2>&1
echo "  gutted dirs left behind: $(list_paths /usr/local/cuda*)"
log_note "purging '*cuda*' also removes cuda-keyring, taking NVIDIA's repo and 600 pin with it"
log_note "our own pin file belongs to no package, so it survives:"
find /etc/apt/preferences.d -maxdepth 1 -type f -printf '    %f\n' 2>/dev/null
expect "zsh no-op with gutted dirs present" "$(zprobe)" "NONE|0|NONE"
expect "dash no-op with gutted dirs present" "$(sprobe dash)" "NONE|0|NONE"

# ---------------------------------------------------------------------------
log_section "RESULT"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}${PASS_COUNT} passed, ${FAIL_COUNT} failed${RESET}"
else
    echo -e "  ${RED}${PASS_COUNT} passed, ${FAIL_COUNT} failed${RESET}"
fi
[ "$FAIL_COUNT" -eq 0 ]
