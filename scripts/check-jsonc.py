#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///
"""
Validate JSON-with-comments (JSONC) files.

The stock `check-json` pre-commit hook uses Python's strict json module, which rejects
comments -- so JSONC files like .devcontainer/devcontainer.json and cmux's config had to
be excluded from it, leaving them with no syntax checking at all. This is the checker
for those files: comments (and trailing commas) are allowed, everything else is still
strict JSON.

The file on disk is only ever read. Comments are ignored for the duration of a parse by
building a comment-free copy of the *text in memory*; the file keeps every comment it
has. Comment spans are blanked rather than deleted so that reported line/column numbers
still point at the right place in the original file.

Usage (pre-commit passes the filenames):

    uv run scripts/check-jsonc.py .devcontainer/devcontainer.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


class JsoncError(ValueError):
    """A JSONC file that cannot be parsed even once comments are ignored."""


def uncomment(text: str) -> str:
    """Blank out JSONC comments, leaving a string strict json can parse.

    Scans character by character so that comment markers *inside strings* are treated as
    data. A regex would truncate `"https://example.com"` at the `//` and then report a
    bogus syntax error on a perfectly valid file.

    Comments become spaces (newlines preserved) so offsets, and therefore the line and
    column in any error message, still match the original file.
    """
    out: list[str] = []
    i = 0
    n = len(text)

    while i < n:
        char = text[i]

        if char == '"':
            start = i
            i += 1
            while i < n:
                if text[i] == "\\":  # escape: consume the escaped char too, so \" does
                    i += 2           # not look like the end of the string
                    continue
                if text[i] == '"':
                    i += 1
                    break
                i += 1
            out.append(text[start:i])
            continue

        if char == "/" and i + 1 < n:
            nxt = text[i + 1]

            if nxt == "/":
                while i < n and text[i] != "\n":
                    out.append(" ")
                    i += 1
                continue

            if nxt == "*":
                end = text.find("*/", i + 2)
                if end == -1:
                    line = text.count("\n", 0, i) + 1
                    raise JsoncError(f"unterminated block comment starting on line {line}")
                for ch in text[i : end + 2]:
                    out.append("\n" if ch == "\n" else " ")
                i = end + 2
                continue

        out.append(char)
        i += 1

    return "".join(out)


def drop_trailing_commas(text: str) -> str:
    """Blank commas that sit just before a closing brace/bracket.

    VS Code's jsonc-parser tolerates trailing commas, so a file that is valid in the
    editor must not fail this hook. Assumes comments are already gone; still string-aware
    so a comma inside a string value is left alone.
    """
    chars = list(text)
    i = 0
    n = len(chars)

    while i < n:
        char = chars[i]

        if char == '"':
            i += 1
            while i < n:
                if chars[i] == "\\":
                    i += 2
                    continue
                if chars[i] == '"':
                    break
                i += 1
            i += 1
            continue

        if char == ",":
            j = i + 1
            while j < n and chars[j].isspace():
                j += 1
            if j < n and chars[j] in "}]":
                chars[i] = " "

        i += 1

    return "".join(chars)


def loads_jsonc(text: str) -> Any:
    """Parse JSONC text into Python objects. Strict JSON once comments are ignored."""
    return json.loads(drop_trailing_commas(uncomment(text)))


def check_file(path: Path) -> str | None:
    """Return an error message if `path` is not valid JSONC, else None. Never writes."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        return exc.strerror or str(exc)

    try:
        loads_jsonc(text)
    except (JsoncError, json.JSONDecodeError, UnicodeDecodeError) as exc:
        return str(exc)

    return None


def main(argv: list[str]) -> int:
    failed = False

    for name in argv:
        error = check_file(Path(name))
        if error is not None:
            print(f"{name}: {error}", file=sys.stderr)
            failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
