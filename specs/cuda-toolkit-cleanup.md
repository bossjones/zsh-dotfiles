# CUDA toolkit cleanup — traps and learnings

Record of what actually went wrong (and nearly went wrong) while retiring CUDA 11.8/12.1 and
installing 13.0 on an Ubuntu 22.04 box with an RTX 3060 Ti on driver 580.173.02.

Read this before touching NVIDIA packages again. Several items below are near-misses that would have
destroyed a working GPU driver, and every one was found empirically — not one was predicted by
reading documentation.

Related: [`docs/testing-and-ci.md`](../docs/testing-and-ci.md#cuda--gpu-verification-rigs) ·
[`docs/tutorials/07-verify-cuda-before-applying.md`](../docs/tutorials/07-verify-cuda-before-applying.md) ·
[`scripts/cuda-verify-config.sh`](../scripts/cuda-verify-config.sh) ·
[`scripts/cuda-verify-gpu.sh`](../scripts/cuda-verify-gpu.sh)

---

## 1. `nvidia-driver-<old>` depends on `nvidia-driver-<new>` — the manual-root trap

**This is the one that nearly deleted a working driver.**

After upgrading 550 → 580, `nvidia-driver-550` remained installed as a metapackage whose only
dependency was:

```
Depends: nvidia-driver-580
```

`nvidia-driver-580` itself was marked **auto**. So `nvidia-driver-550` was the *only manually-marked
root* keeping the entire 580 stack reachable. Marking the apparently-obsolete 550 package `auto`:

```sh
sudo apt-mark auto nvidia-driver-550     # DO NOT do this without checking first
```

instantly made `apt autoremove` want to remove **46 packages**, including `nvidia-driver-580`,
`nvidia-dkms-580`, `dkms`, every `libnvidia-*-580`, and `xserver-xorg-video-nvidia-580` — i.e. the GPU
driver and the X video driver.

**Before marking any nvidia package auto, find the real manual root:**

```sh
apt-mark showmanual | grep -E 'nvidia|cuda'
apt-cache depends nvidia-driver-<old>          # often: Depends: nvidia-driver-<new>
sudo apt-get -s autoremove | grep -cE '^(Remv|Purg) '
```

The correct end state is that the **current** driver is the manual root:

```sh
sudo apt-mark manual nvidia-driver-580
sudo apt-get -s autoremove          # must not list any 580 package
```

Second-order lesson: a package being old is not evidence it is unused. Check the dependency
direction — NVIDIA's Ubuntu metapackages point *forward* to newer series.

## 2. `apt` prints `Purg`, not `Remv`, for `--purge`

A gate script guarding the driver grepped only `^Remv `:

```sh
apt-get -s remove --purge "*cuda*" ... | grep -c '^Remv '     # -> 0, always
```

It reported "0 packages, GATE PASS" while the real operation would remove 118. **The gate was
vacuous on the single check protecting the driver.** Always match both verbs:

```sh
grep -cE '^(Remv|Purg) '
```

And make a zero-match result a hard failure, never a pass:

```sh
[ "$total" -eq 0 ] && { echo "ABORT: simulation matched nothing"; exit 1; }
```

## 3. Pinning the driver to Ubuntu builds: pattern gaps

`cuda-keyring` installs `/etc/apt/preferences.d/cuda-repository-pin-600`, which pins **NVIDIA's
entire repo to priority 600** — above Ubuntu's default 500. After adding the repo, `apt upgrade`
prefers NVIDIA's driver builds unless counter-pinned. NVIDIA ships `nvidia-driver-580` at
`580.178.04-1ubuntu1`, which outranks Ubuntu's `580.173.02-0ubuntu0.22.04.1`.

The naive counter-pin is wrong in **both** directions:

- `Package: nvidia-* libnvidia-*` is **too broad** — it blocks `nvidia-container-toolkit`
  (`E: Package 'nvidia-container-toolkit' has no installation candidate`), `libnvidia-container1`,
  `nvidia-fs` and `nvidia-gds`, none of which have an Ubuntu-archive alternative.
- Specific patterns are **too narrow** — two driver-adjacent packages slipped through and were only
  caught by measurement: `libxnvctrl0` (NVIDIA ships 610.57.04 against a 580 driver) and
  `libnvidia-egl-wayland1` (NVIDIA `1:1.1.21` vs Ubuntu `1:1.1.9`, both amd64 and i386).

The working pin is in [`scripts/cuda-verify-config.sh`](../scripts/cuda-verify-config.sh) (stage 1).
Whatever patterns you use, **the invariant is what matters** — re-check it after any pin or repo
change:

```sh
apt-get -s upgrade | grep -cE '^Inst (nvidia-|libnvidia-|xserver-xorg-video-nvidia|libxnvctrl)'
# must print 0
```

A pin test without a **negative control** proves nothing. Check `apt-cache policy` both with and
without the pin file; the "before" must show the NVIDIA build winning.

## 4. What `apt purge "*cuda*"` does and does not match

NVIDIA's documented removal (installation guide §12) behaves as follows on this system:

| | |
|---|---|
| **Matched** (118 pkgs) | all `cuda-*`, `libcu*`, `libnpp*`, `libnvjpeg*`, `libnvjitlink*`, `nsight-*`, `gds-tools-*`, `nvidia-gds*` |
| **Also matched** | **`cuda-keyring`** — removing NVIDIA's `sources.list` *and* their 600 pin |
| **Not matched** | `nvidia-fs`, `nvidia-fs-dkms` (become orphans; `autoremove` collects them) |
| **Not matched** | **`cudnn-*`** — spelled "cudnn", so an 853 MB `/var/cudnn-local-repo-*` survives |
| **Never touched** | the 580 driver stack, `nvidia-container-toolkit`, `libnvidia-container1` |

A hand-written pin file under `/etc/apt/preferences.d/` belongs to no package, so it **survives** a
purge that wipes everything package-owned. That is what makes "pin first, then add the repo" work.

`/var/cuda-repo-*-local` payloads (3 GB each here) are owned by the `cuda-repo-*-local` packages and
disappear with them — no manual `rm` needed.

## 5. `LD_LIBRARY_PATH` for CUDA is unnecessary *and* harmful

`/usr/local/cuda-X/lib64` is a symlink to `targets/x86_64-linux/lib`, which the `.deb` packages
already register via `/etc/ld.so.conf.d/000_cuda.conf`. Verified: `ldconfig -p | grep libcudart`
returns matches with `LD_LIBRARY_PATH` unset. NVIDIA's guide states the variable is required for
**runfile** installs only.

Because `LD_LIBRARY_PATH` outranks the `ldconfig` cache, a stale value silently shadows correct
libraries — e.g. forcing 11.8's `libcublas` into a process wanting a newer one. Removing the export
was a bug fix, not tidying.

## 6. Toolkit/driver compatibility: two different minimums

Conflating these leads to either over-caution or a broken install:

- **Per-release minimum** ("CUDA Toolkit and Corresponding Driver Versions"): CUDA 13.0 GA needs
  ≥ 580.65.06; 13.0 Update 3 needs ≥ 580.126.20; **13.3 Update 1 needs ≥ 610.43.02**.
- **Minor-version compatibility minimum**: CUDA 13.x needs only ≥ 580.

Driver 580.173.02 therefore satisfies every CUDA **13.0** point release, but is below 13.3's stated
requirement. Hence `cuda-toolkit-13-0`, pinned to the series — **never** `cuda` (pulls
`cuda-drivers`, replacing the driver) and **never** plain `cuda-toolkit` (floats to the newest
series).

## 7. Verifying PTX JIT requires a kernel that is actually launched

The sharpest driver/toolkit compatibility test is forcing the driver to JIT-compile PTX:

```sh
nvcc -arch=compute_86 -code=compute_86 -o probe probe.cu
```

But a `probe.cu` that only calls runtime-API functions compiles to a binary with **no device code at
all** — confirmed with `cuobjdump --dump-ptx`: 0 `.entry` markers. The test then passes even on a
driver that could not JIT anything. The probe must contain a `__global__` kernel **and launch it**.
Self-check before trusting the result:

```sh
cuobjdump --dump-ptx probe | grep -c '\.entry'    # expect >= 1
cuobjdump --dump-elf probe | grep -c 'elf code'   # expect 0 (no cubin fallback)
```

## 8. Container testing: no GPU needed for the shell logic; CDI avoids a Docker restart

The shell modules only inspect the filesystem, so [`Dockerfile.cuda`](../Dockerfile.cuda) needs no
GPU and no `nvidia-container-toolkit`. `cuda-toolkit-<series>-config-common` is ~16 KB and owns the
`/usr/local/cuda` symlink, the `update-alternatives` registration and `000_cuda.conf` — so a faithful
test costs kilobytes.

Its postinst runs `update-alternatives` against `/usr/local/cuda-<ver>`, which must **exist** first;
on a real host the content packages create it, so a test fixture has to `mkdir -p` it or the install
fails.

For driver checks ([`Dockerfile.gpu`](../Dockerfile.gpu)), CDI needs no `daemon.json` edit and no
daemon restart (Docker 25+), so running containers are undisturbed:

```sh
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
docker run --rm --device nvidia.com/gpu=all nvidia/cuda:13.0.0-devel-ubuntu22.04 ...
```

Compose's documented `deploy.resources.reservations.devices` block goes through the nvidia *runtime*
and does require the restart; the CDI equivalent is a plain `devices:` entry.

## 9. `chezmoi source-path` already includes `home/`

`.chezmoiroot` redirects the source root, so `chezmoi source-path` returns `.../chezmoi/home`. The
module is at `$(chezmoi source-path)/shell/cuda/custom.zsh`; writing `.../home/shell/...` doubles the
segment and silently sources nothing.

## 10. `grep -q` + `pipefail` + `tar` produces false negatives

Verifying a backup's contents this way reports MISSING for files that are present:

```sh
tar tzf archive.tgz | grep -qx "etc/some/file"      # under set -o pipefail
```

`grep -q` exits on first match, `SIGPIPE`s `tar`, and `pipefail` surfaces tar's failure as the
pipeline status. Materialise the listing first:

```sh
tar tzf archive.tgz > /tmp/listing && grep -qxF "etc/some/file" /tmp/listing
```

---

## Process lessons

The technical traps above are individually obscure. What actually prevented damage was procedure:

1. **Simulate, then read the simulation.** `apt-get -s` before every destructive step, checked
   against an explicit list of packages that must survive. This caught the driver near-miss in §1.
2. **Treat a zero-result check as a failure, not a pass.** Both vacuous gates here (§2, §10) *reported
   success*. If a check cannot fail, it is not a check.
3. **Always include a negative control.** For a pin, confirm the wrong thing wins without it.
4. **Verify on the real target.** The pin gaps in §3 and the metapackage trap in §1 do not appear in
   documentation or in a container — only on the actual host.
5. **Distrust plans, including this one.** The `apt-mark auto nvidia-driver-550` step came from an
   approved written plan built on a misread `dpkg -l`. The gate caught it; the plan did not.
