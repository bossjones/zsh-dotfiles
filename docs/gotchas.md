# Gotchas &amp; Known Cleanup

> An honest list of warts, dead code, and sharp edges an expert should know about — and a newcomer should not waste an afternoon on.

**Nothing on this page is changed by the documentation effort that created it.** These are observations recorded against the source as of this writing, offered as candidates for future cleanup. Each entry cites the file so you can verify it yourself.

**See also:** [Shell Loading](shell-loading.md) · [Provisioning Scripts](provisioning-scripts.md) · [Testing &amp; CI](testing-and-ci.md)

---

## At a glance

| # | Issue | Impact | Suggested fix |
|---|-------|--------|---------------|
| 1 | [`home/shell/zsh_dot_d/{before,after}/`](../home/shell/zsh_dot_d) is orphaned (20 files, loaded by nothing) | Dead code; misleads readers into thinking it runs | Remove, or migrate any still-wanted logic into a real module |
| 2 | `~/.zshrc.local` is rendered but never sourced | Its darwin/arm64 config may be silently inert | Verify; source it from `config.zsh`, or fold its content in |
| 3 | `pytest-rerunfailures` pinned twice in [`requirements-test.txt`](../requirements-test.txt) | Harmless but sloppy | Delete the duplicate line |
| 4 | [`run_onchange_before_99-macos-osx-settings.sh.tmpl`](../home/.chezmoiscripts/run_onchange_before_99-macos-osx-settings.sh.tmpl) is a comment-only stub | Implies macOS defaults auto-apply; they don't | Wire up `~/.osx --no-restart`, or remove the stub |
| 5 | README structure tree had stale paths | Confusing onboarding | Addressed in this docs pass |
| 6 | `ruby`, `nodejs`, `k8s`, `fnm` feature flags are **inert** — recorded in chezmoi data but read by no template | Toggling them silently does nothing | Wire them to real gates, or drop the prompts |
| 7 | `run_before-00-*` / `run_after-00-*` scripts use a **hyphen**, not the `before_`/`after_` underscore chezmoi requires | They run in the "during" bucket, interleaved with file writes — not strictly before/after | Rename to `run_before_00-…` / `run_after_00-…` |

---

## 1. `zsh_dot_d/before` and `zsh_dot_d/after` are dead code

[`home/shell/zsh_dot_d/`](../home/shell/zsh_dot_d) contains 20 `.zsh` files under `before/` and `after/` (`go.zsh`, `rust.zsh`, `history.zsh`, `ffmpeg.zsh`, `aws_utils.zsh`, `tmux.zsh`, `custom.zsh`, …). They look load-bearing. They are not.

**Why they never run:** the shell loads modules exclusively through sheldon's globs (see [Shell Loading](shell-loading.md)), which match the **exact basenames** `env.zsh`, `path.zsh`, `aliases.zsh`, `config.zsh`, `keybinding.zsh`, `completion.zsh`. Files like `before/go.zsh` or `after/history.zsh` match none of those, and nothing else sources the directory:

```sh
grep -rn "zsh_dot_d" home/    # → no matches
```

They are legacy from an earlier oh-my-zsh-style `.zsh.d` loader; their logic has largely migrated into the tool subdirectories (e.g. `before/go.zsh` → `home/shell/go/env.zsh`).

**Recommendation:** delete the tree, or if any snippet is still wanted, move it into the correct `home/shell/<tool>/{env,path,aliases}.zsh` so the glob picks it up.

---

## 2. `~/.zshrc.local` is generated but nothing sources it

[`home/dot_zshrc.local.tmpl`](../home/dot_zshrc.local.tmpl) renders to `~/.zshrc.local` on darwin/arm64 and contains real configuration (extra history options, `direnv hook`, `globalias`, completion styles).

**The catch:** Zsh only auto-sources `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, `.zlogout` — **not** `.zshrc.local`. And nothing in this repo sources it explicitly:

```sh
grep -rn "zshrc.local" home/   # → no matches
```

So unless a plugin happens to source it, that file's settings may never take effect.

**Recommendation:** confirm whether it is loaded on a real machine (`echo` a marker inside it and start a shell). If not, either add `[ -f ~/.zshrc.local ] && source ~/.zshrc.local` to `home/shell/config.zsh`, or migrate its content into `config.zsh` / `dot_zshrc.local`-aware logic and drop the file.

---

## 3. Duplicate test dependency pin

[`requirements-test.txt`](../requirements-test.txt) lists `pytest-rerunfailures` on **two consecutive lines** (26 and 27). Pip tolerates it, so nothing breaks — but it's noise.

**Recommendation:** remove one line. (`pyproject.toml` is the primary dependency source under `uv`; `requirements-test.txt` is the legacy flat list used by the CI `pip install` step.)

---

## 4. The macOS "osx settings" script is a stub

[`run_onchange_before_99-macos-osx-settings.sh.tmpl`](../home/.chezmoiscripts/run_onchange_before_99-macos-osx-settings.sh.tmpl) is only a shebang and a comment:

```bash
#!/usr/bin/env zsh
# ~/.osx --no-restart
```

It runs on every macOS apply but does nothing. The substantive macOS defaults live in [`home/executable_dot_osx`](../home/executable_dot_osx) (`~/.osx`) and must be **run by hand** — they are *not* applied automatically by `chezmoi apply`. Reading the script name alone, you'd reasonably assume otherwise. See [iTerm2 &amp; macOS](iterm2-and-macos.md#macos-system-defaults-osx).

**Recommendation:** either uncomment/implement the `~/.osx --no-restart` invocation (accepting the tradeoff that system-defaults changes then run on every apply), or delete the stub to remove the false impression.

---

## 5. Stale README paths (addressed in this pass)

The previous `README.md` structure tree referenced `ai_docs/summaries/` (the real subdirectories are `reports/`, `workflows/`, `cheatsheets/`) and showed `dot_zshrc` / `dot_zshenv` without the `.tmpl` suffix they actually carry. These were corrected while rewriting the README as a documentation hub. Noted here for completeness.

---

## 6. Several feature flags are inert

Of the seven boolean feature flags collected at `chezmoi init` (`ruby`, `pyenv`, `nodejs`, `k8s`, `opencv`, `fnm`, `cuda`), **four are never read by any template**. They are dutifully stored in `~/.config/chezmoi/chezmoi.yaml` but consulted by nothing, so toggling them has no effect.

Verify it yourself — only `.tmpl` files can act on a flag:

```sh
for f in ruby nodejs k8s fnm opencv cuda pyenv; do
  echo "== $f =="; grep -rl "\.$f\b" home/ --include='*.tmpl' | grep -v chezmoi.yaml.tmpl
done
```

| Flag | Read by a template? | Verdict |
|------|--------------------|---------|
| `pyenv` | ✅ 5 files (compat scripts + install scripts) | **Live** — a real, cross-cutting gate |
| `opencv` | ✅ 2 Linux install scripts | **Live** on Linux only |
| `cuda` | ✅ sheldon `plugins.toml.tmpl` (×2) | **Live** (and the `cuda` module is itself Ubuntu/Oracle-gated) |
| `ruby` | ❌ none | **Inert** |
| `nodejs` | ❌ none | **Inert** |
| `k8s` | ❌ none | **Inert** — the only `.k8s` hit in the tree is `events.k8s.io` inside a kubectl loop |
| `fnm` | ❌ none | **Inert** — the only `.fnm` hit is a commented-out `$HOME/.fnm` in `path.zsh` |

Ruby, Node, and Kubernetes tooling still get installed by other means (the version manager's fixed tool list, aliases, etc.) — but **not because of these flags**. Either wire the flags into real conditionals or remove the prompts so the config stops implying a toggle that doesn't exist. See [Feature Flags](feature-flags.md#chezmoi-feature-booleans).

---

## 7. `run_before-` / `run_after-` scripts use the wrong separator

chezmoi recognizes ordering by the tokens `run_before_` and `run_after_` — with an **underscore**. These seven scripts use a **hyphen** instead:

```
run_before-00-prereq-centos.sh.tmpl        run_after-00-adhoc-centos.sh.tmpl
run_before-00-prereq-centos-pyenv.sh.tmpl  run_after-00-adhoc-macos.sh.tmpl
run_before-00-prereq-ubuntu.sh.tmpl        run_after-00-adhoc-ubuntu.sh.tmpl
run_before-00-prereq-ubuntu-pyenv.sh.tmpl
```

Because `before-00-…` doesn't match the `before_` token, chezmoi parses these as ordinary `run_` scripts with **default ("during") order** — they execute interleaved with regular file application (sorted by name), rather than strictly *before* or *after* everything else. In practice the current set still works because their effects (installing prereqs, ad-hoc fixups) aren't order-sensitive against the managed files — but the names are misleading and the guarantee they imply doesn't hold.

**Recommendation:** rename to `run_before_00-…` / `run_after_00-…` (underscore) to get the intended phase ordering. This is a source change, out of scope for the docs pass that recorded it. See [Provisioning Scripts](provisioning-scripts.md) for how the phases are supposed to order.

---

## Reporting or fixing

These are documentation observations, not tracked issues. If you pick one up, the relevant deep-dive pages ([Shell Loading](shell-loading.md), [Provisioning Scripts](provisioning-scripts.md), [Testing &amp; CI](testing-and-ci.md)) describe the surrounding machinery so a fix stays consistent with the existing conventions.
