# Plan: Make `dsf` read its slice-domain list from an external file

## Context

Make `dsf` (the `yt-dlp` wrapper) decide whether to add the `-I "1::2"`
playlist-slice flag based on a list of domains read from an external file
(`~/.config/yt-dlp/slice-domains.txt`), instead of hardcoding the domain list in
the function body.

**Reality check (confirmed by reading the source):** the `dsf` in this repo is
**not** the config-driven, `youtube.com`-branching wrapper referenced in the
request. It is currently:

```zsh
alias dsf='dl-safe-fork'
```

where `dl-safe-fork` is a thumbnail/fallback-chain downloader
(`dl-thumb-fork` → on failure `yt-best-fork` → on failure raw
`yt-dlp --cookies-from-browser Firefox`). There is no `--config-locations`, no
`youtube.com`/`youtu.be` branch, and no `-I "1::2"` in `dsf` today.

**Decisions (confirmed):**
1. **Replace** `dsf` with the config-driven reference implementation (a thin
   `yt-dlp --config-locations ~/.config/yt-dlp/config` wrapper + slice-domains
   logic). The old fallback-chain behavior for `dsf` is intentionally dropped.
2. **Remove dead code**: also delete the `dl-safe-fork` function and the
   `alias dlsf='dl-safe-fork'`, since nothing else references them.

Intended outcome: `dsf` becomes a small function that reads
`~/.config/yt-dlp/slice-domains.txt`, substring-matches the URL against each
non-comment/non-blank line, and adds `-I "1::2"` only on a match — falling back
gracefully (plain `yt-dlp`) when the file is missing or nothing matches.

## Objective

- Convert `dsf` from an alias into a standalone zsh function whose slice-domain
  list comes from `~/.config/yt-dlp/slice-domains.txt`.
- Delete the now-unused `dl-safe-fork` function and `dlsf` alias.
- Preserve `--config-locations ~/.config/yt-dlp/config` on both branches.
- Behave safely when the domains file is absent or matches nothing (plain
  `yt-dlp` call, no error).

## Solution Approach

Replace the `dl-safe-fork` definition + `dlsf`/`dsf` aliases (a single
contiguous block) with one `dsf()` function that:
- reads `$HOME/.config/yt-dlp/slice-domains.txt` line by line **only if it
  exists** (`[[ -f ... ]]` guard),
- skips blank lines and `#`-comment lines,
- does a substring match (`[[ "$url" == *"$domain"* ]]`) — same match style
  the request asked for,
- runs `yt-dlp --config-locations ~/.config/yt-dlp/config -I "1::2" "$url"` on a
  match, else `yt-dlp --config-locations ~/.config/yt-dlp/config "$url"`.

`sleep_dsf` (which calls `dsf "${1}"`) keeps working unchanged — it just picks
up the new function.

**Do NOT create or seed `~/.config/yt-dlp/slice-domains.txt`** — assume it
already exists and is populated. It is user-local data and is **not** to be
added to the chezmoi source tree.

## Relevant Files

- `home/shell/customs/aliases.zsh` — **the only file to modify.** This is the
  real chezmoi source file; it is a **plain** `.zsh` file (no `.tmpl`, zero Go
  template `{{ }}` syntax), sourced in-place by Sheldon from
  `~/.local/share/chezmoi/home/shell/customs/aliases.zsh` (see
  `home/private_dot_config/sheldon/plugins.toml.tmpl` `[plugins.bossaliases]`).
  No separate rendered dotfile exists. Region of interest:
  - lines **423–445**: `dl-safe-fork () { ... }` → delete
  - line **447**: `alias dlsf='dl-safe-fork'` → delete
  - line **448**: `alias dsf='dl-safe-fork'` → replace with new `dsf()` function
  - lines **450–453**: `sleep_dsf` → keep as-is (calls the new `dsf`)

### Patterns to reuse (already in this file)
- `dl-split` (line ~395) uses `while IFS="" read -r p || [ -n "$p" ]; do` — the
  `|| [[ -n "$x" ]]` guard handles a final line with no trailing newline. Reuse
  this idiom in the read loop rather than a bare `while read`.
- `dl_using_chrome` (line ~2724) is the existing example of the `-I "1::2"`
  slice flag; `dsfi` (line ~500) is the existing `--config-locations`-adjacent
  wrapper style. Reference only — do not modify these.

### Files explicitly NOT touched
- `dl-thumb-fork`, `yt-best-fork` — standalone functions called by the old
  `dl-safe-fork`; leave defined (they may be used elsewhere / directly).
- `~/.config/yt-dlp/slice-domains.txt` — assumed to already exist; not created,
  not added to chezmoi.

## Step by Step Tasks
IMPORTANT: Execute every step in order, top to bottom.

### 1. Delete the old `dl-safe-fork` block
- In `home/shell/customs/aliases.zsh`, remove the entire `dl-safe-fork () { ... }`
  function (lines ~423–445) **and** the `alias dlsf='dl-safe-fork'` line (~447).

### 2. Replace the `dsf` alias with a real function
- Replace `alias dsf='dl-safe-fork'` (line ~448) with this function:

```zsh
dsf() {
	local url="$1"
	local list_file="$HOME/.config/yt-dlp/slice-domains.txt"
	local match=false
	local domain

	if [[ -f "$list_file" ]]; then
		while IFS= read -r domain || [[ -n "$domain" ]]; do
			# skip blank lines and #-comments
			[[ -z "$domain" || "$domain" == \#* ]] && continue
			if [[ "$url" == *"$domain"* ]]; then
				match=true
				break
			fi
		done < "$list_file"
	fi

	if [[ "$match" == true ]]; then
		yt-dlp --config-locations ~/.config/yt-dlp/config -I "1::2" "$url"
	else
		yt-dlp --config-locations ~/.config/yt-dlp/config "$url"
	fi
}
```

- Keep the file's existing tab-indentation style (this file uses tabs).
- Leave `sleep_dsf` (lines ~450–453) unchanged.

### 3. Sanity-check surrounding structure
- Confirm no dangling references remain: `grep -n 'dl-safe-fork\|dlsf' home/shell/customs/aliases.zsh`
  should return **nothing** after the edit.

### 4. Validate (see Validation Commands)
- Syntax-check, load the function, and prove the branch selection with an
  offline `yt-dlp` shim before trusting it.

## Testing Strategy

The real-world checks require network + a populated
`~/.config/yt-dlp/slice-domains.txt`. For deterministic, offline verification of
the branching logic during the build, shadow `yt-dlp` with a shim that just
echoes its arguments, and drive `dsf` against matching/non-matching URLs with a
temp domains file. Cover:
- matching URL (e.g. `youtube.com`) → output contains `-I 1::2`
- non-matching URL (e.g. `vimeo.com`) → output does **not** contain `-I`
- comment (`#...`) and blank lines in the file are skipped
- missing file → still runs the plain branch, no error
- domains-file present but no match → plain branch, no error

## Acceptance Criteria

- `dsf` is a function (not an alias); `type dsf` shows a function body.
- `dl-safe-fork` and `alias dlsf=...` no longer exist in the file.
- On a URL matching a line in `~/.config/yt-dlp/slice-domains.txt`, the invocation
  includes `--config-locations ~/.config/yt-dlp/config -I "1::2"`.
- On a non-matching URL, the invocation is
  `yt-dlp --config-locations ~/.config/yt-dlp/config "$url"` (no `-I`).
- `#`-comment lines and blank lines in the file are ignored.
- Missing file ⇒ plain (`no -I`) branch, no error/crash.
- `--config-locations ~/.config/yt-dlp/config` is present on **both** branches.
- `zsh -n home/shell/customs/aliases.zsh` passes.
- The domains file is not created and not added to the chezmoi tree.

## Validation Commands

Run from the repo root (`/Users/bossjones/dev/bossjones/zsh-dotfiles`):

```bash
# 1. Syntax check the whole file
zsh -n home/shell/customs/aliases.zsh

# 2. No dead references remain
grep -n 'dl-safe-fork\|dlsf' home/shell/customs/aliases.zsh   # expect: no output

# 3. Offline branch-selection proof (shim yt-dlp, don't hit the network)
zsh -c '
  set -e
  # extract just the dsf function into the current shell
  eval "$(awk "/^dsf\(\) \{/,/^\}/" home/shell/customs/aliases.zsh)"
  type dsf >/dev/null || { echo "dsf not defined"; exit 1; }

  # shim yt-dlp to echo its args instead of downloading
  yt-dlp() { echo "yt-dlp $*"; }

  tmp=$(mktemp -d)
  export HOME="$tmp"; mkdir -p "$tmp/.config/yt-dlp"
  printf "%s\n" "# comment line" "" "youtube.com" "youtu.be" > "$tmp/.config/yt-dlp/slice-domains.txt"

  echo "== matching (youtube) =="
  dsf "https://www.youtube.com/watch?v=fgC6ofVudZA" | tee /dev/stderr | grep -q -- "-I 1::2" && echo "PASS: -I present"

  echo "== non-matching (vimeo) =="
  out=$(dsf "https://vimeo.com/123456789"); echo "$out"
  echo "$out" | grep -q -- "-I" && { echo "FAIL: -I should be absent"; exit 1; } || echo "PASS: no -I"

  echo "== missing file =="
  rm -f "$tmp/.config/yt-dlp/slice-domains.txt"
  out=$(dsf "https://www.youtube.com/watch?v=x"); echo "$out"
  echo "$out" | grep -q -- "-I" && { echo "FAIL: -I should be absent"; exit 1; } || echo "PASS: no -I, no error"
'
```

Then the real-world checks (network + real domains file):

```bash
# reload and confirm definition
source home/shell/customs/aliases.zsh 2>/dev/null; type dsf

# matching URL — confirm -I 1::2 in the actual invocation via yt-dlp verbose/simulate
dsf "https://www.youtube.com/watch?v=fgC6ofVudZA"    # observe -I 1::2 passed
# non-matching URL — confirm -I absent
dsf "https://vimeo.com/<some-id>"
```

## Notes

- **Chezmoi:** `aliases.zsh` is plain (no template) and sourced in-place by
  Sheldon — editing the repo file is what takes effect. `chezmoi apply` is
  **not** to be run on this workstation (dry-run only). The
  `slice-domains.txt` data file stays local, out of the chezmoi source tree.
- **Indentation:** this file uses hard tabs; match it.
