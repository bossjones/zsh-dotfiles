#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "rich>=13.0.0",
# ]
# ///
"""
Pre-apply backup of chezmoi-managed dotfiles.

`chezmoi apply` silently overwrites existing target files in $HOME. This script
snapshots exactly the files chezmoi would touch -- discovered dynamically from
`chezmoi managed` so it never drifts -- into a timestamped .tar.gz plus a JSON
manifest, before a risky apply (or when trying these dotfiles on a machine that
already has configs).

Usage:
    # Back up everything chezmoi manages that currently exists
    uv run scripts/backup-dotfiles.py

    # Preview without writing anything
    uv run scripts/backup-dotfiles.py --dry-run

    # Also include the .chezmoiexternal.yaml git repos under ~/dev/bossjones/
    uv run scripts/backup-dotfiles.py --include-external

    # Preview a restore (writes nothing)
    uv run scripts/backup-dotfiles.py --restore ~/.dotfiles-backups/backup-*.tar.gz

    # Actually restore back into $HOME
    uv run scripts/backup-dotfiles.py --restore <archive> --apply
"""

from __future__ import annotations

import argparse
import hashlib
import json
import socket
import subprocess
import sys
import tarfile
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path

from rich.console import Console
from rich.table import Table

console = Console()
err_console = Console(stderr=True)

# Prefix used inside the archive for files that live outside $HOME, so restore
# can map them back to an unambiguous absolute path.
ABS_PREFIX = "_abs"

# Fallback target list, used only when `chezmoi managed` is unavailable. Mirrors
# the chezmoi source tree (home/dot_*, home/dot_sheldon, home/private_dot_config,
# home/private_dot_bin) as of this writing.
STATIC_TARGETS: tuple[str, ...] = (
    "~/.zshrc",
    "~/.zshrc.local",
    "~/.zprofile",
    "~/.bashrc",
    "~/.profile",
    "~/.gitconfig",
    "~/.gitignore_global",
    "~/.agignore",
    "~/.vimrc",
    "~/.inputrc",
    "~/.irbrc",
    "~/.pdbrc",
    "~/.pdbrc.py",
    "~/.pryrc",
    "~/.pythonrc",
    "~/.rspec",
    "~/.gemrc",
    "~/.osx",
    "~/.sheldon",
    "~/.config/sheldon",
    "~/.bin",
)

# External git repos from .chezmoiexternal.yaml (only backed up with --include-external).
EXTERNAL_TARGETS: tuple[str, ...] = (
    "~/dev/bossjones/oh-my-tmux",
    "~/dev/bossjones/boss-cheatsheets",
)


@dataclass(frozen=True)
class Entry:
    """A single path selected for backup."""

    source: Path  # absolute path on disk
    arcname: (
        str  # path inside the archive (HOME-relative, or _abs/... for outside-HOME)
    )


@dataclass(frozen=True)
class FileRecord:
    """A single file captured in the backup manifest."""

    arcname: str
    size: int
    mode: str
    sha256: str


def _run_chezmoi(args: list[str]) -> str | None:
    """Run a read-only chezmoi subcommand, returning stdout or None on failure."""
    try:
        result = subprocess.run(
            ["chezmoi", *args],
            capture_output=True,
            text=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None
    return result.stdout


def chezmoi_version() -> str:
    """Return the chezmoi version string, or 'unknown' if unavailable."""
    out = _run_chezmoi(["--version"])
    return out.strip() if out else "unknown"


def discover_targets() -> tuple[list[Path], str]:
    """
    Determine which absolute target paths to consider for backup.

    Returns (paths, mode) where mode is 'dynamic' (from `chezmoi managed`) or
    'static' (embedded fallback list). Paths are returned as-is; existence is
    filtered later in build_entries().
    """
    out = _run_chezmoi(["managed", "--path-style", "absolute"])
    if out is not None:
        paths = [Path(line) for line in out.splitlines() if line.strip()]
        if paths:
            return paths, "dynamic"
        # chezmoi present but reported nothing managed -- fall through to static.

    err_console.print(
        "⚠️  [yellow]`chezmoi managed` unavailable; using the embedded static "
        "target list (may be stale).[/yellow]"
    )
    paths = [Path(p).expanduser() for p in STATIC_TARGETS]
    return paths, "static"


def arcname_for(path: Path, home: Path) -> str:
    """Map an absolute path to its archive name (HOME-relative or _abs/...)."""
    try:
        rel = path.relative_to(home)
        return str(rel)
    except ValueError:
        # Outside $HOME -- stash under _abs/<full path without leading slash>.
        return f"{ABS_PREFIX}/{path.as_posix().lstrip('/')}"


def build_entries(paths: list[Path], home: Path, *, include_dirs: bool) -> list[Entry]:
    """
    Keep only paths that currently exist and turn them into Entry objects.

    `chezmoi managed` lists every managed file individually *and* the directories
    that contain them. Recursing into those directories would sweep in unmanaged
    content (e.g. all of ~/.config) and duplicate files, so in dynamic mode we set
    include_dirs=False and back up only the file entries. The static fallback uses
    directory roots (~/.bin, ~/.sheldon) whose files are not listed individually,
    so it sets include_dirs=True and relies on recursion.
    """
    entries: list[Entry] = []
    seen: set[Path] = set()
    for path in paths:
        if path in seen:
            continue
        seen.add(path)
        # Treat broken symlinks as non-existent (lexists would include them).
        if not path.exists():
            continue
        if path.is_dir() and not include_dirs:
            continue
        entries.append(Entry(source=path, arcname=arcname_for(path, home)))
    return entries


def _iter_files(root: Path):
    """Yield every regular file under a path (the path itself if it is a file)."""
    if root.is_file():
        yield root
        return
    for child in sorted(root.rglob("*")):
        if child.is_file() and not child.is_symlink():
            yield child


def _sha256(path: Path) -> str | None:
    """Return the hex sha256 of a file, or None if it cannot be read."""
    h = hashlib.sha256()
    try:
        with path.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 16), b""):
                h.update(chunk)
    except OSError:
        return None
    return h.hexdigest()


def _manifest_records(
    entries: list[Entry], home: Path
) -> tuple[list[FileRecord], int, int]:
    """Build manifest file records; return (records, file_count, total_bytes)."""
    records: list[FileRecord] = []
    total_bytes = 0
    file_count = 0
    for entry in entries:
        for file_path in _iter_files(entry.source):
            try:
                stat = file_path.stat()
            except OSError as exc:
                err_console.print(f"⚠️  [yellow]skipping {file_path}: {exc}[/yellow]")
                continue
            digest = _sha256(file_path)
            if digest is None:
                err_console.print(
                    f"⚠️  [yellow]skipping unreadable {file_path}[/yellow]"
                )
                continue
            records.append(
                FileRecord(
                    arcname=arcname_for(file_path, home),
                    size=stat.st_size,
                    mode=oct(stat.st_mode & 0o777),
                    sha256=digest,
                )
            )
            total_bytes += stat.st_size
            file_count += 1
    return records, file_count, total_bytes


def _human_bytes(n: int) -> str:
    """Render a byte count as a short human-readable string."""
    size = float(n)
    for unit in ("B", "KiB", "MiB", "GiB"):
        if size < 1024 or unit == "GiB":
            return f"{size:.1f} {unit}" if unit != "B" else f"{int(size)} B"
        size /= 1024
    return f"{size:.1f} GiB"


def do_backup(out_dir: Path, *, dry_run: bool, include_external: bool) -> int:
    """Discover, snapshot, and archive managed dotfiles. Returns an exit code."""
    home = Path.home()
    paths, mode = discover_targets()
    # Dynamic mode lists files individually; recursing managed dirs would grab
    # unmanaged content. Static fallback uses dir roots that need recursion.
    entries = build_entries(paths, home, include_dirs=(mode == "static"))

    if include_external:
        if mode == "dynamic":
            console.print(
                "ℹ️  [dim]--include-external is implied in dynamic mode "
                "(chezmoi already manages those repos).[/dim]"
            )
        else:
            ext_paths = [Path(p).expanduser() for p in EXTERNAL_TARGETS]
            seen = {e.source for e in entries}
            entries.extend(
                e
                for e in build_entries(ext_paths, home, include_dirs=True)
                if e.source not in seen
            )

    if not entries:
        err_console.print("❌ [red]No existing target files found to back up.[/red]")
        return 1

    console.print(
        f"🔍 Discovery mode: [bold]{mode}[/bold] — "
        f"{len(entries)} existing target(s) selected."
    )

    records, file_count, total_bytes = _manifest_records(entries, home)

    if dry_run:
        table = Table(title="Would back up (dry run)")
        table.add_column("Archive path", overflow="fold")
        table.add_column("Size", justify="right")
        for rec in records:
            table.add_row(rec.arcname, _human_bytes(rec.size))
        console.print(table)
        console.print(
            f"📦 [bold]{file_count}[/bold] file(s), "
            f"[bold]{_human_bytes(total_bytes)}[/bold] — nothing written (--dry-run)."
        )
        return 0

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    out_dir.mkdir(parents=True, exist_ok=True)
    archive_path = out_dir / f"backup-{stamp}.tar.gz"
    manifest_path = out_dir / f"backup-{stamp}.manifest.json"

    console.print(f"💾 Writing archive to {archive_path} ...")
    try:
        with tarfile.open(archive_path, "w:gz") as tar:
            for entry in entries:
                tar.add(entry.source, arcname=entry.arcname, recursive=True)
    except OSError as exc:
        err_console.print(f"❌ [red]Failed to write archive: {exc}[/red]")
        return 1

    manifest = {
        "created": datetime.now().isoformat(timespec="seconds"),
        "hostname": socket.gethostname(),
        "home": str(home),
        "chezmoi_version": chezmoi_version(),
        "discovery_mode": mode,
        "include_external": include_external,
        "archive": archive_path.name,
        "file_count": file_count,
        "total_bytes": total_bytes,
        "files": [asdict(rec) for rec in records],
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

    console.print("\n✅ [green]Backup complete![/green]")
    console.print(f"   Discovery mode: {mode}")
    console.print(f"   Files:          {file_count}")
    console.print(f"   Total size:     {_human_bytes(total_bytes)}")
    console.print(f"   Archive:        {archive_path}")
    console.print(f"   Manifest:       {manifest_path}")
    return 0


def _safe_target(member_name: str, home: Path) -> Path | None:
    """
    Resolve an archive member name to its on-disk restore target.

    Guards against path traversal: rejects members containing '..' and members
    that would escape $HOME (unless under the _abs/ prefix).
    """
    posix = Path(member_name).as_posix()
    if ".." in Path(posix).parts:
        return None
    if posix == ABS_PREFIX or posix.startswith(f"{ABS_PREFIX}/"):
        rest = posix[len(ABS_PREFIX) :].lstrip("/")
        return Path("/") / rest
    return home / posix


def do_restore(archive: Path, *, apply: bool) -> int:
    """Preview (default) or apply a restore from a backup archive. Returns exit code."""
    home = Path.home()
    if not archive.is_file():
        err_console.print(f"❌ [red]Archive not found: {archive}[/red]")
        return 1

    try:
        tar = tarfile.open(archive, "r:gz")
    except (OSError, tarfile.TarError) as exc:
        err_console.print(f"❌ [red]Cannot open archive: {exc}[/red]")
        return 1

    with tar:
        members = [m for m in tar.getmembers() if m.isfile()]
        if not members:
            err_console.print("❌ [red]Archive contains no files.[/red]")
            return 1

        plan: list[tuple[tarfile.TarInfo, Path, bool]] = []
        for member in members:
            target = _safe_target(member.name, home)
            if target is None:
                err_console.print(
                    f"⚠️  [yellow]skipping unsafe member: {member.name}[/yellow]"
                )
                continue
            plan.append((member, target, target.exists()))

        if not apply:
            table = Table(title=f"Restore preview — {archive.name} (no changes made)")
            table.add_column("Target path", overflow="fold")
            table.add_column("Action")
            for _member, target, exists in plan:
                action = "[red]OVERWRITE[/red]" if exists else "[green]create[/green]"
                table.add_row(str(target), action)
            console.print(table)
            overwrites = sum(1 for _m, _t, exists in plan if exists)
            console.print(
                f"📋 {len(plan)} file(s) would be restored "
                f"([red]{overwrites} overwrite(s)[/red]). "
                "Pass [bold]--apply[/bold] to perform the restore."
            )
            return 0

        restored = 0
        for member, target, _exists in plan:
            extracted = tar.extractfile(member)
            if extracted is None:
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open("wb") as out:
                out.write(extracted.read())
            target.chmod(member.mode & 0o777)
            restored += 1

    console.print(f"\n✅ [green]Restored {restored} file(s) into {home}.[/green]")
    return 0


def build_parser() -> argparse.ArgumentParser:
    """Construct the argparse CLI."""
    parser = argparse.ArgumentParser(
        description="Back up (or restore) chezmoi-managed dotfiles before apply.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path.home() / ".dotfiles-backups",
        help="Output directory for backups (default: ~/.dotfiles-backups).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="List what would be backed up without writing anything.",
    )
    parser.add_argument(
        "--include-external",
        action="store_true",
        help="Also back up the .chezmoiexternal.yaml git repos under ~/dev/bossjones/.",
    )
    parser.add_argument(
        "--restore",
        type=Path,
        metavar="ARCHIVE",
        help="Restore from a backup archive (preview-only unless --apply is given).",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="With --restore, actually write files back into $HOME.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """Entry point: dispatch to backup or restore based on flags."""
    args = build_parser().parse_args(argv)
    try:
        if args.restore is not None:
            return do_restore(args.restore.expanduser(), apply=args.apply)
        return do_backup(
            args.out.expanduser(),
            dry_run=args.dry_run,
            include_external=args.include_external,
        )
    except KeyboardInterrupt:
        err_console.print("\n❌ [red]Interrupted.[/red]")
        return 1


if __name__ == "__main__":
    sys.exit(main())
