"""
Tests for the chezmoi-managed ccstatusline config.

``ccstatusline`` (https://github.com/sirmalloc/ccstatusline) reads its config from a
hardcoded ``~/.config/ccstatusline/settings.json``. We track it in the chezmoi source at
``home/private_dot_config/ccstatusline/settings.json`` so every machine renders the same
Claude Code status line.

Two properties are worth pinning down, and neither is obvious from reading the file:

1. **It must stay machine-agnostic.** ccstatusline writes an ``installation`` block (how
   *this* box installed it -- pinned vs self-managed, npm vs bun, a pinned version) and a
   transient ``updatemessage`` block into the very same file. Committing either would push
   one laptop's install method onto every other machine. ``test_no_machine_local_metadata``
   is the guard.

2. **It must stay a plain file, not a template.** The whole point is that the config is
   byte-identical everywhere -- there is no OS, hostname, or feature-flag branching -- so a
   ``.tmpl`` sibling or a stray ``{{`` would be a regression, not an enhancement.

These are source-tree assertions: they read the file in the repo, not the applied copy in
``$HOME``. Deliberately so -- any TUI tweak on this laptop would otherwise red the suite
until it was re-committed. ``chezmoi status`` is the right tool for drift.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import typing as t
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent

# chezmoi source path. `.chezmoiroot` is `home`, and `private_dot_config/` -> `~/.config/`
# (0700), so this renders to the target below. Intermediate dirs stay plain-named, matching
# the sibling cmux/ ghostty/ iterm2/ payloads.
SOURCE_FILE = REPO_ROOT / "home" / "private_dot_config" / "ccstatusline" / "settings.json"

# The path ccstatusline itself hardcodes (src/utils/config.ts: DEFAULT_SETTINGS_PATH).
TARGET_PATH = ".config/ccstatusline/settings.json"

# Keys ccstatusline writes that describe *this* machine, not the desired status line.
MACHINE_LOCAL_KEYS = (
    "installation",
    "updatemessage",
)

# ccstatusline renders at most three status lines.
MAX_LINES = 3

CHEZMOI = shutil.which("chezmoi")


Settings = dict[str, t.Any]
Widget = dict[str, t.Any]


@pytest.fixture(scope="module")
def settings() -> Settings:
    """The committed config, parsed."""
    data: object = json.loads(SOURCE_FILE.read_text(encoding="utf-8"))
    assert isinstance(data, dict)
    return t.cast(Settings, data)


# --------------------------------------------------------------------------------------
# The file is present and is strict JSON
# --------------------------------------------------------------------------------------


def test_source_file_exists() -> None:
    assert SOURCE_FILE.is_file(), f"{SOURCE_FILE} is missing from the chezmoi source"


def test_parses_as_strict_json() -> None:
    """Not JSONC. Mirrors the ``check-json`` pre-commit hook so ``make test`` catches a
    broken file even when hooks are skipped -- and pins that this file must *not* be added
    to the ``&jsonc_files`` exclude anchor in .pre-commit-config.yaml."""
    json.loads(SOURCE_FILE.read_text(encoding="utf-8"))


# --------------------------------------------------------------------------------------
# Shape: enough to catch a bad hand-merge, not a reimplementation of ccstatusline's schema
# --------------------------------------------------------------------------------------


def test_version_is_an_int(settings: Settings) -> None:
    assert isinstance(settings["version"], int)


def test_lines_shape(settings: Settings) -> None:
    lines: list[list[Widget]] = settings["lines"]
    assert isinstance(lines, list)
    assert 1 <= len(lines) <= MAX_LINES, f"ccstatusline renders at most {MAX_LINES} lines"
    assert any(line for line in lines), "every status line is empty"

    for index, line in enumerate(lines):
        assert isinstance(line, list), f"lines[{index}] is not a list"
        for widget in line:
            assert isinstance(widget, dict), f"lines[{index}] holds a non-object widget"
            assert isinstance(widget.get("id"), str), f"lines[{index}] widget missing str id"
            assert isinstance(widget.get("type"), str), f"lines[{index}] widget missing str type"


def test_widget_ids_are_unique(settings: Settings) -> None:
    """ccstatusline keys widgets by id; duplicates from a hand-merge misbehave silently."""
    lines: list[list[Widget]] = settings["lines"]
    ids: list[str] = [widget["id"] for line in lines for widget in line]
    duplicates = sorted({i for i in ids if ids.count(i) > 1})
    assert not duplicates, f"duplicate widget ids: {duplicates}"


# --------------------------------------------------------------------------------------
# The guarantee that matters most: this config is shared, so it stays machine-agnostic
# --------------------------------------------------------------------------------------


@pytest.mark.parametrize("key", MACHINE_LOCAL_KEYS, ids=lambda k: k)
def test_no_machine_local_metadata(settings: Settings, key: str) -> None:
    """``installation`` records how ccstatusline was installed on one specific box and
    ``updatemessage`` is transient update-nag state. Either one, committed, gets applied to
    every other machine. Strip them before committing a fresh export."""
    assert key not in settings, (
        f"{SOURCE_FILE.name} contains machine-local key {key!r}; "
        "remove it so the config stays identical across machines"
    )


def test_is_not_a_template() -> None:
    """No ``.tmpl`` sibling, and no Go-template delimiters in the body."""
    assert not SOURCE_FILE.with_suffix(".json.tmpl").exists()
    assert "{{" not in SOURCE_FILE.read_text(encoding="utf-8")


def test_matches_ccstatusline_writer_format() -> None:
    """The committed bytes must be exactly what ccstatusline itself would write.

    Every TUI save rewrites the file as ``JSON.stringify(settings, null, 2)`` -- 2-space
    indent, no trailing newline -- which Python reproduces exactly as
    ``json.dumps(..., indent=2, ensure_ascii=False)``. If the committed copy is formatted
    any other way, ``chezmoi status`` reports drift after every save even when nothing
    semantically changed, and the real signal gets lost in the noise.

    This is why ``.pre-commit-config.yaml`` excludes this one file from ``prettier``
    (which collapses single-element arrays onto one line) and from ``end-of-file-fixer``
    (which would append a trailing newline). Re-including it will fail this test.
    """
    raw = SOURCE_FILE.read_text(encoding="utf-8")
    expected = json.dumps(json.loads(raw), indent=2, ensure_ascii=False)
    assert raw == expected, (
        "settings.json is not in ccstatusline's own output format; "
        "re-export it from the TUI (or reformat) instead of letting a formatter touch it"
    )


# --------------------------------------------------------------------------------------
# End-to-end: chezmoi resolves the source path to ~/.config/ccstatusline/settings.json
# --------------------------------------------------------------------------------------


@pytest.mark.skipif(CHEZMOI is None, reason="chezmoi is not installed")
def test_chezmoi_manages_target() -> None:
    """The source path is only correct if chezmoi maps it to the hardcoded target path.

    Read-only: ``chezmoi managed`` never writes. It does need a rendered chezmoi config for
    the ``.chezmoi.yaml.tmpl`` prompts, which exists on a provisioned machine and in CI
    after ``chezmoi init`` -- elsewhere we skip rather than fail.
    """
    assert CHEZMOI is not None
    result = subprocess.run(
        [CHEZMOI, "managed", "--source", str(REPO_ROOT)],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if result.returncode != 0:
        pytest.skip(f"chezmoi managed failed (unprovisioned machine?): {result.stderr.strip()}")

    assert TARGET_PATH in result.stdout.splitlines(), (
        f"chezmoi does not map the source file to {TARGET_PATH}"
    )
