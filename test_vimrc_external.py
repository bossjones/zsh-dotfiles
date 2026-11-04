"""
Tests for the ``~/.vimrc`` / ``~/.vim`` wiring.

Historically ``home/dot_vimrc`` wrote a standalone 93-line ``~/.vimrc`` while a completely
unmanaged ``~/.vim`` clone of gpakosz/.vim sat next to it. On at least one machine the clone
had already won -- ``~/.vimrc`` was a hand-made symlink into it -- so chezmoi's copy was
orphaned and silently diverging. See issue #124.

The fix inverts the ownership:

* ``~/.vim`` is a chezmoi *external* (``git-repo``), pinned to the **bossjones fork** rather
  than gpakosz directly, so upstream churn can never break an ``apply``.
* ``~/.vimrc`` is a chezmoi-managed **symlink** into that clone, which is what the machines
  had already converged on by hand.
* Personal overrides live in ``~/.vimrc.local``, which upstream's ``.vimrc`` sources at the
  very end -- so they layer on top instead of replacing the whole file.

Three properties are worth pinning down:

1. **``home/dot_vimrc`` must stay gone.** chezmoi refuses to build source state when a
   target has two definitions, so re-adding it would fail every apply with
   ``inconsistent state``. ``test_no_orphaned_dot_vimrc`` is the guard.

2. **The external must point at the fork.** Repointing it at ``gpakosz/.vim`` would restore
   the exact fragility the fork exists to remove.

3. **``~/.vimrc.local`` must not re-enable modelines.** Upstream sets ``nomodeline``
   deliberately ("security measure"); the retired ``dot_vimrc`` overrode it. Dropping that
   override was a conscious decision and is easy to reintroduce by accident.

These are source-tree assertions: they read files in the repo, not the applied copies in
``$HOME``. Runtime drift is ``chezmoi status``'s job, and the applied-state equivalent
(asserting ``git -C ~/.vim remote get-url origin``) belongs in the macos-ci VM suite.
"""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).parent
SOURCE_DIR = REPO_ROOT / "home"  # `.chezmoiroot` is `home`

SYMLINK_SOURCE = SOURCE_DIR / "symlink_dot_vimrc"
LOCAL_SOURCE = SOURCE_DIR / "dot_vimrc.local"
EXTERNAL_FILE = SOURCE_DIR / ".chezmoiexternal.yaml"

# The fork. Deliberately HTTPS: an external is fetched non-interactively during `apply`,
# including in CI and in the macos-ci VM guests, where no SSH key is present.
FORK_URL = "https://github.com/bossjones/.vim.git"

# Relative, so the link resolves the same way regardless of what `--destination` is set to.
SYMLINK_TARGET = ".vim/.vimrc"


def _external_block(name: str) -> dict[str, str]:
    """Return the key/value pairs of one top-level entry in ``.chezmoiexternal.yaml``.

    Hand-rolled rather than using PyYAML so the suite gains no new dependency for a
    six-line, flat, comment-heavy block.
    """
    entry: dict[str, str] = {}
    in_block = False
    for raw in EXTERNAL_FILE.read_text().splitlines():
        if raw.startswith(f"{name}:"):
            in_block = True
            continue
        if in_block:
            # A new top-level key (or a top-level comment) ends the block.
            if raw and not raw.startswith((" ", "\t")):
                break
            match = re.match(r"\s+([A-Za-z_]+):\s*(.+?)\s*$", raw)
            if match:
                entry[match.group(1)] = match.group(2)
    return entry


def test_no_orphaned_dot_vimrc() -> None:
    """``home/dot_vimrc`` must not come back -- it collides with the symlink definition."""
    collisions = sorted(p.name for p in SOURCE_DIR.glob("dot_vimrc*") if p.name != "dot_vimrc.local")
    assert collisions == [], (
        f"{collisions} would define ~/.vimrc a second time; chezmoi fails with "
        "'inconsistent state'. ~/.vimrc is owned by home/symlink_dot_vimrc."
    )


def test_vimrc_is_a_symlink_into_the_vim_clone() -> None:
    """``~/.vimrc`` is a symlink whose *content* is the relative path to the clone."""
    assert SYMLINK_SOURCE.is_file(), f"{SYMLINK_SOURCE} is missing"
    assert SYMLINK_SOURCE.read_text().strip() == SYMLINK_TARGET


def test_vim_external_points_at_the_bossjones_fork() -> None:
    """The ``.vim`` external must be a git-repo pinned to the fork, not to gpakosz."""
    entry = _external_block(".vim")
    assert entry, f"no '.vim' entry found in {EXTERNAL_FILE}"
    assert entry.get("type") == "git-repo"
    assert entry.get("url") == FORK_URL, (
        f"expected the bossjones fork ({FORK_URL}), got {entry.get('url')!r}. "
        "Pointing straight at upstream reintroduces the churn the fork exists to absorb."
    )


def test_vimrc_local_exists_and_is_not_a_template() -> None:
    """Overrides are byte-identical on every machine; a ``{{`` would be a regression."""
    assert LOCAL_SOURCE.is_file(), f"{LOCAL_SOURCE} is missing"
    assert not (SOURCE_DIR / "dot_vimrc.local.tmpl").exists()
    assert "{{" not in LOCAL_SOURCE.read_text()


def test_vimrc_local_does_not_re_enable_modelines() -> None:
    """Upstream's ``set nomodeline`` is a security default we chose to keep."""
    offenders = [
        line
        for line in LOCAL_SOURCE.read_text().splitlines()
        if re.match(r"\s*set\s+(modeline|modelines)\b", line)
    ]
    assert offenders == [], (
        f"{offenders} re-enables modelines, which lets any file you open execute vim "
        "settings. Upstream disables them on purpose."
    )
