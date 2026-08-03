#!/usr/bin/env bash
# Verify a CUDA toolkit actually works against the HOST's installed driver.
#
# Runs inside Dockerfile.gpu with the GPU exposed. The container runtime injects
# the host driver, so this is a faithful rehearsal of a toolkit upgrade: point
# CUDA_IMAGE at the toolkit you plan to install, run this, and you learn whether
# your driver can run its output BEFORE touching the host.
#
# The PTX JIT stage is the sharpest check. CUDA minor-version compatibility works
# by the driver JIT-compiling the toolkit's PTX at load time, so a driver that is
# too old fails there even when a prebuilt cubin happens to load fine.
#
# Requires nvidia-container-toolkit on the host and the GPU passed in with either
# --device nvidia.com/gpu=all (CDI) or --gpus all (nvidia runtime).
#
# Usage:
#   ./scripts/cuda-verify-gpu.sh
#   ./scripts/cuda-verify-gpu.sh --help
#   MIN_DRIVER=580.126.20 ./scripts/cuda-verify-gpu.sh   # assert a documented floor
#
set -uo pipefail

case "${1:-}" in
    -h | --help)
        sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
esac

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

# Indent piped input so probe output is visually nested under its section.
indent() { sed 's/^/    /'; }

# ---------------------------------------------------------------------------
# Guard rails - fail with an actionable message, not a confusing stack of errors
# ---------------------------------------------------------------------------
if ! command -v nvidia-smi > /dev/null 2>&1; then
    echo -e "${RED}nvidia-smi not found inside the container.${RESET}" >&2
    echo "The GPU was not exposed. Use one of:" >&2
    echo "  docker run --rm --device nvidia.com/gpu=all ...   # CDI" >&2
    echo "  docker run --rm --gpus all ...                    # nvidia runtime" >&2
    exit 2
fi
if ! nvidia-smi -L > /dev/null 2>&1; then
    echo -e "${RED}nvidia-smi present but no GPU visible.${RESET}" >&2
    echo "Is nvidia-container-toolkit installed on the host?" >&2
    exit 2
fi
if ! command -v nvcc > /dev/null 2>&1; then
    echo -e "${RED}nvcc not found.${RESET} Use a -devel image, not -base or -runtime." >&2
    exit 2
fi

# ---------------------------------------------------------------------------
log_section "Host driver, as seen from inside the container"
nvidia-smi --query-gpu=driver_version,name,compute_cap,memory.total \
    --format=csv,noheader | indent
DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1 | tr -d '[:space:]')
CAP=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -1 | tr -d '[:space:]. ')
log_pass "GPU visible; host driver ${DRIVER}, compute capability ${CAP}"

if [ -n "${MIN_DRIVER:-}" ]; then
    lowest=$(printf '%s\n%s\n' "$MIN_DRIVER" "$DRIVER" | sort -V | head -1)
    if [ "$lowest" = "$MIN_DRIVER" ]; then
        log_pass "driver ${DRIVER} >= documented minimum ${MIN_DRIVER}"
    else
        log_fail "driver too old" "${DRIVER} < required ${MIN_DRIVER}"
    fi
fi

# ---------------------------------------------------------------------------
log_section "Toolkit in this image"
nvcc --version | tail -2 | indent
TOOLKIT=$(nvcc --version | grep -o 'release [0-9.]*' | awk '{print $2}')
if [ -n "$TOOLKIT" ]; then
    log_pass "toolkit is CUDA ${TOOLKIT}"
else
    log_fail "could not determine the toolkit version"
fi

# ---------------------------------------------------------------------------
log_section "Is this GPU's architecture still a supported target?"
if nvcc --list-gpu-arch 2>/dev/null | grep -qx "compute_${CAP}"; then
    log_pass "sm_${CAP} is in CUDA ${TOOLKIT}'s target list"
else
    log_fail "sm_${CAP} is unsupported by CUDA ${TOOLKIT}" \
        "targets: $(nvcc --list-gpu-arch 2>/dev/null | tr '\n' ' ')"
    log_note "a toolkit dropping your architecture is a hard blocker, not a warning"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "${WORK}/probe.cu" << 'PROBE_CU'
#include <cstdio>

__global__ void addk(const float* a, const float* b, float* c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}

int main() {
    int driver_api = 0, runtime_api = 0;
    cudaDriverGetVersion(&driver_api);
    cudaRuntimeGetVersion(&runtime_api);
    printf("driver_api=%d runtime_api=%d\n", driver_api, runtime_api);
    if (driver_api < runtime_api) {
        printf("WARN driver API is older than the runtime API\n");
    }

    cudaDeviceProp prop{};
    if (cudaGetDeviceProperties(&prop, 0) != cudaSuccess) {
        printf("PROPS_FAIL\n");
        return 2;
    }
    printf("device=%s sm=%d.%d\n", prop.name, prop.major, prop.minor);

    const int n = 1 << 20;
    float* ha = (float*)malloc(n * sizeof(float));
    float* hb = (float*)malloc(n * sizeof(float));
    float* hc = (float*)malloc(n * sizeof(float));
    for (int i = 0; i < n; i++) { ha[i] = 1.5f; hb[i] = 2.25f; }

    float *da, *db, *dc;
    if (cudaMalloc(&da, n * sizeof(float)) != cudaSuccess) {
        printf("MALLOC_FAIL\n");
        return 3;
    }
    cudaMalloc(&db, n * sizeof(float));
    cudaMalloc(&dc, n * sizeof(float));
    cudaMemcpy(da, ha, n * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(db, hb, n * sizeof(float), cudaMemcpyHostToDevice);

    addk<<<(n + 255) / 256, 256>>>(da, db, dc, n);
    cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
        printf("KERNEL_FAIL=%s\n", cudaGetErrorString(err));
        return 4;
    }

    cudaMemcpy(hc, dc, n * sizeof(float), cudaMemcpyDeviceToHost);
    int wrong = 0;
    for (int i = 0; i < n; i++) {
        if (hc[i] < 3.74f || hc[i] > 3.76f) wrong++;
    }
    printf("mismatches=%d\n", wrong);
    printf("%s\n", wrong == 0 ? "COMPUTE_OK" : "COMPUTE_BAD");
    return wrong == 0 ? 0 : 5;
}
PROBE_CU

# ---------------------------------------------------------------------------
log_section "Build a real cubin for sm_${CAP} and execute it on driver ${DRIVER}"
if nvcc "-arch=sm_${CAP}" -o "${WORK}/probe" "${WORK}/probe.cu" 2> "${WORK}/nvcc.err"; then
    log_pass "nvcc -arch=sm_${CAP} compiled and linked"

    cubin_out=$("${WORK}/probe" 2>&1)
    cubin_rc=$?
    printf '%s\n' "$cubin_out" | indent

    if [ "$cubin_rc" -eq 0 ]; then
        log_pass "CUDA ${TOOLKIT} binary executed on driver ${DRIVER} (exit 0)"
    else
        log_fail "execution failed" "exit ${cubin_rc}"
    fi

    if echo "$cubin_out" | grep -q COMPUTE_OK; then
        log_pass "results numerically correct (1M-element vector add)"
    else
        log_fail "results incorrect or kernel did not run"
    fi

    driver_api=$(echo "$cubin_out" | sed -n 's/.*driver_api=\([0-9]*\).*/\1/p' | head -1)
    runtime_api=$(echo "$cubin_out" | sed -n 's/.*runtime_api=\([0-9]*\).*/\1/p' | head -1)
    if [ -n "$driver_api" ]; then
        log_note "driver exposes CUDA driver API ${driver_api}; toolkit runtime API is ${runtime_api}"
    fi
else
    log_fail "compile failed" "$(tail -3 "${WORK}/nvcc.err")"
fi

# ---------------------------------------------------------------------------
log_section "PTX JIT: no cubin, so the driver must compile the PTX itself"
log_note "this is the mechanism CUDA minor-version compatibility relies on"
if nvcc "-arch=compute_${CAP}" "-code=compute_${CAP}" \
    -o "${WORK}/probe_ptx" "${WORK}/probe.cu" 2> "${WORK}/ptx.err"; then
    ptx_out=$("${WORK}/probe_ptx" 2>&1)
    ptx_rc=$?
    printf '%s\n' "$ptx_out" | indent
    if [ "$ptx_rc" -eq 0 ]; then
        log_pass "driver ${DRIVER} JIT-compiled CUDA ${TOOLKIT} PTX successfully"
    else
        log_fail "PTX JIT failed" "exit ${ptx_rc} - driver ${DRIVER} is too old for toolkit ${TOOLKIT}"
    fi
else
    log_fail "PTX build failed" "$(tail -3 "${WORK}/ptx.err")"
fi

# ---------------------------------------------------------------------------
log_section "RESULT"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}${PASS_COUNT} passed, ${FAIL_COUNT} failed${RESET}"
    echo "  Toolkit CUDA ${TOOLKIT} is safe to install against driver ${DRIVER}."
else
    echo -e "  ${RED}${PASS_COUNT} passed, ${FAIL_COUNT} failed${RESET}"
    echo "  Do NOT install toolkit CUDA ${TOOLKIT} against driver ${DRIVER} until this is green."
fi
[ "$FAIL_COUNT" -eq 0 ]
