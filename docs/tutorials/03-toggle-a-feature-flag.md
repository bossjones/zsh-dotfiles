# Tutorial 03: Toggle a Feature Flag

> Turn an optional install on (or off) after the fact — e.g. enable `pyenv` — without re-running the whole first-time setup.

**See also:** [docs/feature-flags.md](../feature-flags.md) (full flag reference) · [Tutorial 00](00-first-time-setup.md) · [Tutorials index](README.md)

---

## What you'll learn

- Two ways to change a boolean chezmoi prompt after initial setup: full re-prompt, or a single non-interactive flag
- How to preview the effect before applying
- How to confirm the gated install script actually ran

**Prerequisites:** [Tutorial 00](00-first-time-setup.md) completed.

**Time estimate:** 10 minutes.

---

## Which flags actually gate something today

`home/.chezmoi.yaml.tmpl` defines seven boolean prompts (`ruby`, `pyenv`, `nodejs`, `k8s`, `cuda`, `fnm`, `opencv`), but **not all of them currently gate an install script on every platform**. Verified by reading the actual `.tmpl` conditionals:

| Flag | Gates something on macOS today? | Where |
|------|----------------------------------|-------|
| `pyenv` | **Yes** | [`run_onchange_before_02-macos-install-pyenv.sh.tmpl`](../../home/.chezmoiscripts/run_onchange_before_02-macos-install-pyenv.sh.tmpl): `{{- if and (eq .chezmoi.os "darwin") .pyenv -}}` |
| `opencv` | Linux only (Ubuntu/CentOS install-deps scripts check `{{ if .opencv -}}`) | [`run_onchange_before_02-ubuntu-install-opencv-deps.sh.tmpl`](../../home/.chezmoiscripts/run_onchange_before_02-ubuntu-install-opencv-deps.sh.tmpl) |
| `k8s`, `fnm`, `ruby`, `nodejs`, `cuda` | Recorded in chezmoi data, but not yet threaded into a macOS install conditional (kubectl/helm/k9s/etc. currently install unconditionally via the asdf/mise plugin lists) | See [docs/feature-flags.md](../feature-flags.md#planned--not-yet-live) |

This tutorial uses **`pyenv`** as the worked example because it's the one with a real, verifiable gate on macOS today. The re-prompt mechanism below is identical for every flag — once `k8s`/`fnm` gain real conditionals, the same steps apply.

---

## Option 1: Re-run all prompts

Clears every cached answer in `~/.config/chezmoi/chezmoi.yaml` and asks again, one at a time:

```sh
chezmoi init --data=false
```

Answer `pyenv` with `true` this time (keep everything else the same, or change as you like). Then preview and apply:

```sh
chezmoi diff
chezmoi apply -v
```

---

## Option 2: Flip just one flag, non-interactively

If you only want to change `pyenv` and don't want to re-answer every other prompt:

```sh
chezmoi init --source=. --promptBool "pyenv=true"
```

This is the same flag mechanism the [`make macos-init-good-defaults-*`](../installation.md#option-4-make-macos-init-good-defaults--canned-answers-repeatable) targets use for a full canned answer set — you're just passing one override instead of all of them.

Preview, then apply:

```sh
chezmoi diff
chezmoi apply -v
```

---

## What happens next

Because [`run_onchange_before_02-macos-install-pyenv.sh.tmpl`](../../home/.chezmoiscripts/run_onchange_before_02-macos-install-pyenv.sh.tmpl) is a `run_onchange_` script, changing `.pyenv` from `false` to `true` changes its **rendered content** (the `{{- if ... .pyenv -}}` block now renders its body instead of nothing), so chezmoi treats it as "changed" and runs it on the next `chezmoi apply`. It installs pyenv via Homebrew and the pinned Python version (`myPyenvPythonVersion`, currently `3.12.8` in `home/.chezmoi.yaml.tmpl`) if it isn't already present.

---

## Verify

```sh
# 1. Confirm the flag is now recorded as true
chezmoi data | grep pyenv

# 2. Confirm pyenv itself is installed
pyenv --version

# 3. Confirm the target Python version is installed under pyenv
pyenv versions
```

Open a **new** shell afterward — `pyenv`'s init hooks (see `home/compat.sh.tmpl` / `home/compat.bash.tmpl`) only take effect in a freshly started shell.

If the flag flipped in `chezmoi data` but nothing installed, check the script actually re-ran:

```sh
chezmoi apply --dry-run --verbose --source=.
```

A dry-run showing the pyenv install script as "would run" (rather than nothing) confirms chezmoi noticed the content change; run `chezmoi apply -v` again if it hadn't executed yet.

---

## Next steps

- **[docs/feature-flags.md](../feature-flags.md)** — the complete flag reference, including which ones are "planned / not yet live"
- **[Tutorial 04: Switch Version Manager](04-switch-version-manager.md)** — the one flag (`version_manager`) that's threaded through the *entire* system
