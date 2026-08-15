# Tutorial 06: Customize iTerm2

> Export your own iTerm2 preferences into the tracked plist, let chezmoi's self-verifying importer apply them on another machine, and install the fonts the profiles expect.

**See also:** [docs/iterm2-and-macos.md](../iterm2-and-macos.md) (full reference) · [docs/provisioning-scripts.md](../provisioning-scripts.md) · [Tutorials index](README.md)

---

## What you'll learn

- Where the tracked iTerm2 settings snapshot lives and how it's applied
- Why the import script **refuses to run while iTerm2 is running** — and why that's correct behavior, not a bug
- How to export your own tweaked profile into the repo
- How to confirm the import actually landed, using the same self-check the script performs

**Prerequisites:** macOS, iTerm2 installed, [Tutorial 00](00-first-time-setup.md) completed.

**Time estimate:** 10–15 minutes.

---

## How it fits together

| Piece | File | Deployed to |
|-------|------|-------------|
| iTerm2 preferences snapshot | [`home/private_dot_config/iterm2/private_com.googlecode.iterm2.plist`](../../home/private_dot_config/iterm2/private_com.googlecode.iterm2.plist) | `~/.config/iterm2/com.googlecode.iterm2.plist` |
| Import script | [`home/.chezmoiscripts/run_onchange_after_60-macos-iterm2-settings.sh.tmpl`](../../home/.chezmoiscripts/run_onchange_after_60-macos-iterm2-settings.sh.tmpl) | Runs on `chezmoi apply` (macOS only) |
| Nerd Font installer | [`home/.chezmoiscripts/run_onchange_after_59-macos-install-fonts.sh.tmpl`](../../home/.chezmoiscripts/run_onchange_after_59-macos-install-fonts.sh.tmpl) | Runs on `chezmoi apply` (macOS only), before the iTerm2 import (`59` sorts before `60`) |

Full detail: **[docs/iterm2-and-macos.md](../iterm2-and-macos.md)**.

---

## Step 1: Understand why iTerm2 must be quit first

This is the part that trips people up. iTerm2 holds its settings **in memory** and writes them back to the plist **when it quits**. If the import ran while iTerm2 was open, iTerm2 would silently overwrite the freshly-imported values the next time it quit — undoing your changes with no error.

So the script checks `pgrep -xq iTerm2` first, and if it's running:

```
================================================================================
iterm2: iTerm2 is RUNNING -- SKIPPING settings import!
iterm2: Your profiles/colors were NOT imported. To fix, quit iTerm2, then run:
iterm2:
iterm2:   defaults import com.googlecode.iterm2 ~/.config/iterm2/com.googlecode.iterm2.plist
iterm2:
iterm2: (or re-run this from Terminal.app while iTerm2 is not running)
================================================================================
```

and exits `0` (not a failure — it's an intentional, informative skip).

---

## Step 2: Export your current iTerm2 preferences

With iTerm2 open, tweak whatever you want (colors, fonts, keybindings, profiles), then quit iTerm2 (**Cmd-Q**, not just close the window) so it flushes its in-memory state to its plist.

Export the live preferences domain to the path this repo tracks:

```sh
mkdir -p ~/.config/iterm2
defaults export com.googlecode.iterm2 ~/.config/iterm2/com.googlecode.iterm2.plist
```

---

## Step 3: Copy it into the chezmoi source

Bring the exported plist into the tracked source file so it becomes part of the repo:

```sh
cp ~/.config/iterm2/com.googlecode.iterm2.plist \
   "$(chezmoi source-path)/home/private_dot_config/iterm2/private_com.googlecode.iterm2.plist"
```

(`chezmoi source-path` prints your chezmoi source directory, so this works regardless of where it's checked out.)

---

## Step 4: Preview, then apply

The import script is a `run_onchange_after_` script keyed on a sha256 hash of the plist embedded directly in its rendered comment (`{{ include "..." | sha256sum }}`) — so changing the plist automatically makes chezmoi treat the script as "changed" and re-run it:

```sh
chezmoi diff --source=.
# or
chezmoi apply --dry-run --verbose --source=.
```

Confirm the diff shows the plist content changing, then apply for real — **with iTerm2 fully quit**:

```sh
chezmoi apply -v --source=.
```

---

## Step 5: Install the fonts the profiles reference

The tracked profiles reference two Nerd Font variants (PostScript names `DroidSansMNF`, `HackNF-Regular`); Monaco and Menlo ship with macOS already. The font installer runs automatically on `chezmoi apply` (before the iTerm2 import, since `59` sorts before `60`), installing via Homebrew casks:

```sh
brew list --cask font-droid-sans-mono-nerd-font 2>/dev/null || brew install --cask font-droid-sans-mono-nerd-font
brew list --cask font-hack-nerd-font 2>/dev/null || brew install --cask font-hack-nerd-font
```

You don't need to run this manually — it's idempotent and chezmoi handles it — but it's useful to know if a profile's font looks wrong and you want to confirm the cask installed.

---

## Verify

The import script self-verifies by comparing the plist's `Default Bookmark Guid` against what actually landed in the live defaults domain. Run the same check yourself:

```sh
# 1. What guid does the tracked plist say should be the default profile?
expected_guid="$(/usr/libexec/PlistBuddy -c 'Print :"Default Bookmark Guid"' ~/.config/iterm2/com.googlecode.iterm2.plist)"

# 2. What guid is actually active in the com.googlecode.iterm2 domain?
actual_guid="$(defaults read com.googlecode.iterm2 "Default Bookmark Guid")"

# 3. They should match
[ "$expected_guid" = "$actual_guid" ] && echo "OK: import verified" || echo "MISMATCH: re-run the import"

# 4. Count how many profiles are registered
defaults read com.googlecode.iterm2 "New Bookmarks" | grep -cE '^ *Guid = '
```

If the guids don't match, iTerm2 was probably still running (or got reopened) during the last `chezmoi apply` — quit it fully and re-run `chezmoi apply -v`.

---

## Next steps

- **[docs/iterm2-and-macos.md](../iterm2-and-macos.md)** — the full flowchart of the import script's logic, plus the (currently unused) `~/.osx` macOS system-defaults script
- **[docs/provisioning-scripts.md](../provisioning-scripts.md)** — how `run_onchange_after_` scripts decide when to re-run, in general
