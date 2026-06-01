"""
Tests for ``scripts/backup-dotfiles.py``.

The script is a standalone PEP 723 ``uv run`` tool with a hyphenated filename, so it
cannot be imported by name -- it is loaded once via importlib (see the ``mod`` fixture).

The tests are deterministic and self-contained: ``chezmoi`` is never invoked for real
(the script's ``_run_chezmoi`` seam is monkeypatched), and ``$HOME`` is a throwaway
``tmp_path`` directory. The most important test is the regression guard for the bug
found during the script's initial verification -- ``chezmoi managed`` lists managed
*directories* as well as files, and recursing into them once produced a 694 MB archive
full of unmanaged content instead of ~224 KB of managed files.
"""

from __future__ import annotations

import importlib.util
import json
import sys
import tarfile
from pathlib import Path
from types import ModuleType

import pytest

SCRIPT_PATH = Path(__file__).parent / "scripts" / "backup-dotfiles.py"


@pytest.fixture(scope="session")
def mod() -> ModuleType:
    """Load the hyphenated backup script as an importable module."""
    spec = importlib.util.spec_from_file_location("backup_dotfiles", SCRIPT_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    # Register before exec so @dataclass can resolve the module via sys.modules.
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def fake_home(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """A throwaway $HOME. Setting the env var keeps Path.home() AND ~ expansion
    (os.path.expanduser, used by the static target list) consistent and isolated."""
    home = tmp_path / "home"
    home.mkdir()
    monkeypatch.setenv("HOME", str(home))
    return home


def _write(path: Path, content: str = "x") -> Path:
    """Create a file (and parents) with some content; return it."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    return path


# --------------------------------------------------------------------------- #
# Pure helpers
# --------------------------------------------------------------------------- #


def test_arcname_for_in_home(mod: ModuleType, tmp_path: Path) -> None:
    home = tmp_path
    assert mod.arcname_for(home / ".gitconfig", home) == ".gitconfig"
    assert mod.arcname_for(home / ".config" / "sheldon" / "plugins.toml", home) == (
        ".config/sheldon/plugins.toml"
    )


def test_arcname_for_outside_home(mod: ModuleType, tmp_path: Path) -> None:
    home = tmp_path / "home"
    outside = Path("/etc/hosts")
    arc = mod.arcname_for(outside, home)
    assert arc == f"{mod.ABS_PREFIX}/etc/hosts"


def test_safe_target_normal_and_abs(mod: ModuleType, tmp_path: Path) -> None:
    home = tmp_path / "home"
    assert mod._safe_target(".gitconfig", home) == home / ".gitconfig"
    assert mod._safe_target(f"{mod.ABS_PREFIX}/etc/hosts", home) == Path("/etc/hosts")


def test_safe_target_rejects_traversal(mod: ModuleType, tmp_path: Path) -> None:
    home = tmp_path / "home"
    assert mod._safe_target("../../etc/passwd", home) is None
    assert mod._safe_target("a/../../b", home) is None


@pytest.mark.parametrize(
    ("n", "expected"),
    [
        (0, "0 B"),
        (512, "512 B"),
        (1024, "1.0 KiB"),
        (1536, "1.5 KiB"),
        (1024 * 1024, "1.0 MiB"),
    ],
)
def test_human_bytes(mod: ModuleType, n: int, expected: str) -> None:
    assert mod._human_bytes(n) == expected


# --------------------------------------------------------------------------- #
# build_entries -- the 694 MB regression guard
# --------------------------------------------------------------------------- #


def test_build_entries_dynamic_excludes_directories(
    mod: ModuleType, tmp_path: Path
) -> None:
    """Dynamic mode (include_dirs=False) must drop managed *directory* entries."""
    home = tmp_path / "home"
    managed_file = _write(home / ".gitconfig")
    managed_dir = home / ".config" / "sheldon"
    _write(managed_dir / "plugins.toml")
    # chezmoi reports both the dir and the file inside it.
    paths = [managed_file, managed_dir, managed_dir / "plugins.toml"]

    entries = mod.build_entries(paths, home, include_dirs=False)
    sources = {e.source for e in entries}

    assert managed_dir not in sources, "managed directory must be excluded in dynamic mode"
    assert managed_file in sources
    assert managed_dir / "plugins.toml" in sources


def test_build_entries_static_keeps_directories(
    mod: ModuleType, tmp_path: Path
) -> None:
    """Static fallback (include_dirs=True) keeps directory roots for recursion."""
    home = tmp_path / "home"
    bin_dir = home / ".bin"
    _write(bin_dir / "tool")

    entries = mod.build_entries([bin_dir], home, include_dirs=True)
    assert [e.source for e in entries] == [bin_dir]


def test_build_entries_skips_missing_and_dedupes(
    mod: ModuleType, tmp_path: Path
) -> None:
    home = tmp_path / "home"
    present = _write(home / ".vimrc")
    missing = home / ".does-not-exist"

    entries = mod.build_entries([present, missing, present], home, include_dirs=False)
    assert [e.source for e in entries] == [present]


# --------------------------------------------------------------------------- #
# discover_targets
# --------------------------------------------------------------------------- #


def test_discover_targets_dynamic(
    mod: ModuleType, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(
        mod, "_run_chezmoi", lambda args: "/home/u/.zshrc\n/home/u/.bin\n"
    )
    paths, mode = mod.discover_targets()
    assert mode == "dynamic"
    assert paths == [Path("/home/u/.zshrc"), Path("/home/u/.bin")]


def test_discover_targets_static_fallback(
    mod: ModuleType, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(mod, "_run_chezmoi", lambda args: None)
    paths, mode = mod.discover_targets()
    assert mode == "static"
    # Embedded static list, tilde-expanded.
    assert Path("~/.zshrc").expanduser() in paths
    assert len(paths) == len(mod.STATIC_TARGETS)


# --------------------------------------------------------------------------- #
# do_backup
# --------------------------------------------------------------------------- #


def _seed_managed_tree(home: Path, mod: ModuleType, monkeypatch: pytest.MonkeyPatch):
    """Create a managed file + a managed dir that also holds an UNMANAGED file.

    Returns (managed_paths_reported_by_chezmoi, unmanaged_file).
    """
    gitconfig = _write(home / ".gitconfig", "[user]\n")
    sheldon = home / ".config" / "sheldon"
    plugins = _write(sheldon / "plugins.toml", "shell = 'zsh'\n")
    # Unmanaged junk living inside the managed directory (e.g. a cache).
    unmanaged = _write(sheldon / "junk.cache", "y" * 4096)

    reported = "\n".join(str(p) for p in (gitconfig, sheldon, plugins)) + "\n"
    monkeypatch.setattr(mod, "_run_chezmoi", lambda args: reported)
    return [gitconfig, plugins], unmanaged


def test_do_backup_dynamic_writes_archive_and_manifest(
    mod: ModuleType,
    fake_home: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    managed, unmanaged = _seed_managed_tree(fake_home, mod, monkeypatch)
    out = tmp_path / "backups"

    rc = mod.do_backup(out, dry_run=False, include_external=False)
    assert rc == 0

    archives = list(out.glob("backup-*.tar.gz"))
    manifests = list(out.glob("backup-*.manifest.json"))
    assert len(archives) == 1 and len(manifests) == 1

    names = set(tarfile.open(archives[0]).getnames())
    assert ".gitconfig" in names
    assert ".config/sheldon/plugins.toml" in names
    # The 694 MB regression: unmanaged content inside the managed dir must NOT appear.
    assert ".config/sheldon/junk.cache" not in names

    manifest = json.loads(manifests[0].read_text())
    assert manifest["discovery_mode"] == "dynamic"
    assert manifest["file_count"] == len(managed)
    arcnames = {rec["arcname"] for rec in manifest["files"]}
    assert arcnames == {".gitconfig", ".config/sheldon/plugins.toml"}
    for rec in manifest["files"]:
        assert len(rec["sha256"]) == 64


def test_do_backup_dry_run_writes_nothing(
    mod: ModuleType,
    fake_home: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _seed_managed_tree(fake_home, mod, monkeypatch)
    out = tmp_path / "backups"

    rc = mod.do_backup(out, dry_run=True, include_external=False)
    assert rc == 0
    assert not out.exists() or not list(out.glob("backup-*"))


def test_do_backup_static_fallback(
    mod: ModuleType,
    fake_home: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    # chezmoi unavailable -> static list. Seed one of the static targets.
    _write(fake_home / ".zshrc", "echo hi\n")
    monkeypatch.setattr(mod, "_run_chezmoi", lambda args: None)
    out = tmp_path / "backups"

    rc = mod.do_backup(out, dry_run=False, include_external=False)
    assert rc == 0
    manifest = json.loads(next(out.glob("backup-*.manifest.json")).read_text())
    assert manifest["discovery_mode"] == "static"
    assert ".zshrc" in {rec["arcname"] for rec in manifest["files"]}


def test_do_backup_no_targets_returns_error(
    mod: ModuleType,
    fake_home: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    # Dynamic discovery returns a path that does not exist -> nothing to back up.
    monkeypatch.setattr(
        mod, "_run_chezmoi", lambda args: str(fake_home / ".nonexistent") + "\n"
    )
    rc = mod.do_backup(tmp_path / "backups", dry_run=False, include_external=False)
    assert rc == 1


# --------------------------------------------------------------------------- #
# do_restore
# --------------------------------------------------------------------------- #


def _make_backup(
    mod: ModuleType,
    fake_home: Path,
    out: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> Path:
    _seed_managed_tree(fake_home, mod, monkeypatch)
    assert mod.do_backup(out, dry_run=False, include_external=False) == 0
    return next(out.glob("backup-*.tar.gz"))


def test_do_restore_preview_writes_nothing(
    mod: ModuleType,
    fake_home: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    archive = _make_backup(mod, fake_home, tmp_path / "backups", monkeypatch)
    before = fake_home / ".gitconfig"
    original = before.read_text()
    before.write_text("MUTATED")  # ensure preview does not clobber it back

    rc = mod.do_restore(archive, apply=False)
    assert rc == 0
    assert before.read_text() == "MUTATED"  # untouched by preview
    assert original != "MUTATED"


def test_do_restore_apply_round_trips(
    mod: ModuleType,
    fake_home: Path,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    archive = _make_backup(mod, fake_home, tmp_path / "backups", monkeypatch)
    gitconfig = fake_home / ".gitconfig"
    plugins = fake_home / ".config" / "sheldon" / "plugins.toml"
    expected_git = gitconfig.read_text()
    expected_plugins = plugins.read_text()

    # Clobber both, then restore.
    gitconfig.write_text("BROKEN")
    plugins.unlink()

    rc = mod.do_restore(archive, apply=True)
    assert rc == 0
    assert gitconfig.read_text() == expected_git
    assert plugins.read_text() == expected_plugins


def test_do_restore_missing_archive(mod: ModuleType, tmp_path: Path) -> None:
    assert mod.do_restore(tmp_path / "nope.tar.gz", apply=False) == 1


# --------------------------------------------------------------------------- #
# CLI wiring
# --------------------------------------------------------------------------- #


def test_main_dispatches_to_restore(
    mod: ModuleType, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    calls: dict[str, object] = {}

    def fake_restore(archive: Path, *, apply: bool) -> int:
        calls["archive"] = archive
        calls["apply"] = apply
        return 0

    monkeypatch.setattr(mod, "do_restore", fake_restore)
    rc = mod.main(["--restore", str(tmp_path / "a.tar.gz"), "--apply"])
    assert rc == 0
    assert calls["apply"] is True
    assert calls["archive"] == tmp_path / "a.tar.gz"
