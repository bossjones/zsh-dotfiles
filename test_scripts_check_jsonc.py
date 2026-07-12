"""
Tests for ``scripts/check-jsonc.py``.

The script is a standalone PEP 723 ``uv run`` tool with a hyphenated filename, so it
cannot be imported by name -- it is loaded once via importlib (see the ``mod`` fixture),
mirroring ``test_scripts_backup_dotfiles.py``.

The checker is read-only: it answers "would this parse as JSON once comments are
ignored?" without ever writing to the file. Comments are the whole point of the JSONC
files it guards, so ``test_never_modifies_file`` pins that guarantee down.

Most of the remaining tests defend against *false alarms* rather than missed errors: a
naive comment scanner sees the ``//`` in ``"https://example.com"`` and blanks the rest
of the line, which turns a perfectly valid file into a bogus syntax error. The real
cmux config opens with exactly such a ``$schema`` URL.
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from types import ModuleType

import pytest

REPO_ROOT = Path(__file__).parent
SCRIPT = REPO_ROOT / "scripts" / "check-jsonc.py"

# The two real JSONC files in the repo that the pre-commit hook is scoped to.
REAL_JSONC_FILES = [
    REPO_ROOT / ".devcontainer" / "devcontainer.json",
    REPO_ROOT / "home" / "private_dot_config" / "cmux" / "private_cmux.json",
]


@pytest.fixture(scope="module")
def mod() -> ModuleType:
    spec = importlib.util.spec_from_file_location("check_jsonc", SCRIPT)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["check_jsonc"] = module
    spec.loader.exec_module(module)
    return module


def _write(tmp_path: Path, content: str, name: str = "sample.json") -> Path:
    path = tmp_path / name
    path.write_text(content, encoding="utf-8")
    return path


# --------------------------------------------------------------------------------------
# Accepts: plain JSON and every flavour of JSONC comment
# --------------------------------------------------------------------------------------


def test_plain_json_passes(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, '{"a": 1}')
    assert mod.check_file(path) is None


def test_full_line_comment_passes(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, '{\n  // a comment\n  "a": 1\n}')
    assert mod.check_file(path) is None


def test_leading_comment_before_opening_brace_passes(mod: ModuleType, tmp_path: Path) -> None:
    # This is devcontainer.json's exact shape: a // comment on line 1, before the `{`.
    path = _write(tmp_path, '// For format details, see https://aka.ms/devcontainer.json.\n{\n  "a": 1\n}')
    assert mod.check_file(path) is None


def test_trailing_comment_after_value_passes(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, '{\n  "a": 1,  // why a is 1\n  "b": 2\n}')
    assert mod.check_file(path) is None


def test_block_comment_passes(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, '{\n  /* block */\n  "a": 1\n}')
    assert mod.check_file(path) is None


def test_multiline_block_comment_passes(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, '{\n  /* line one\n     line two */\n  "a": 1\n}')
    assert mod.check_file(path) is None


def test_trailing_comma_in_object_and_array_passes(mod: ModuleType, tmp_path: Path) -> None:
    # VS Code's jsonc-parser tolerates these, so a file that is valid in the editor
    # must not fail the hook.
    path = _write(tmp_path, '{\n  "a": [1, 2,],\n  "b": 2,\n}')
    assert mod.check_file(path) is None


# --------------------------------------------------------------------------------------
# False-alarm guards: comment markers that live *inside strings* are data, not comments
# --------------------------------------------------------------------------------------


def test_double_slash_inside_string_is_not_a_comment(mod: ModuleType, tmp_path: Path) -> None:
    # The real cmux file opens with a $schema URL containing "//".
    path = _write(
        tmp_path,
        '{\n  "$schema": "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json",\n'
        '  "schemaVersion": 1\n}',
    )
    assert mod.check_file(path) is None


def test_url_value_survives_intact(mod: ModuleType, tmp_path: Path) -> None:
    # Not just "does it parse" -- the value must not be truncated at the "//".
    text = '{"url": "https://example.com/a/b"}'
    assert mod.loads_jsonc(text) == {"url": "https://example.com/a/b"}


def test_block_comment_markers_inside_string_are_data(mod: ModuleType, tmp_path: Path) -> None:
    assert mod.loads_jsonc('{"a": "/* not a comment */"}') == {"a": "/* not a comment */"}


def test_escaped_quote_does_not_end_string(mod: ModuleType, tmp_path: Path) -> None:
    # If the scanner thinks the escaped quote closes the string, it will treat the
    # following // as a comment and eat the rest of the line, breaking the parse.
    assert mod.loads_jsonc(r'{"a": "she said \"// hi\"", "b": 2}') == {
        "a": 'she said "// hi"',
        "b": 2,
    }


def test_comment_like_text_in_key_is_data(mod: ModuleType, tmp_path: Path) -> None:
    assert mod.loads_jsonc('{"http://k": 1}') == {"http://k": 1}


# --------------------------------------------------------------------------------------
# Rejects: still strict JSON once comments are ignored
# --------------------------------------------------------------------------------------


def test_missing_brace_fails(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, '{\n  // fine\n  "a": 1\n')
    assert mod.check_file(path) is not None


def test_unquoted_key_fails(mod: ModuleType, tmp_path: Path) -> None:
    # JSON5 would accept this; JSONC does not, and neither do we.
    path = _write(tmp_path, "{\n  a: 1\n}")
    assert mod.check_file(path) is not None


def test_single_quoted_string_fails(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, "{\n  \"a\": 'x'\n}")
    assert mod.check_file(path) is not None


def test_unterminated_block_comment_fails(mod: ModuleType, tmp_path: Path) -> None:
    path = _write(tmp_path, '{\n  /* never closed\n  "a": 1\n}')
    assert mod.check_file(path) is not None


# --------------------------------------------------------------------------------------
# CLI contract: mirrors check-json (silent on success, path in the message on failure)
# --------------------------------------------------------------------------------------


def test_main_clean_run_is_silent_and_exits_zero(
    mod: ModuleType, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    good = _write(tmp_path, '{\n  // ok\n  "a": 1\n}')
    assert mod.main([str(good)]) == 0
    captured = capsys.readouterr()
    assert captured.out == ""
    assert captured.err == ""


def test_main_reports_only_the_bad_file(
    mod: ModuleType, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    good = _write(tmp_path, '{"a": 1}', name="good.json")
    bad = _write(tmp_path, "{oops}", name="bad.json")

    assert mod.main([str(good), str(bad)]) != 0

    err = capsys.readouterr().err
    assert "bad.json" in err
    assert "good.json" not in err


def test_main_on_missing_file_fails_without_traceback(
    mod: ModuleType, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    missing = tmp_path / "nope.json"
    assert mod.main([str(missing)]) != 0
    assert "nope.json" in capsys.readouterr().err


# --------------------------------------------------------------------------------------
# The guarantee that matters most: the checker never touches the file
# --------------------------------------------------------------------------------------


@pytest.mark.parametrize(
    "content",
    [
        pytest.param('{\n  // keep me\n  "a": 1,  // and me\n  "u": "https://x/y"\n}', id="valid-jsonc"),
        pytest.param('{\n  // keep me\n  "a": oops\n}', id="invalid-jsonc"),
    ],
)
def test_never_modifies_file(mod: ModuleType, tmp_path: Path, content: str) -> None:
    path = _write(tmp_path, content)
    before = path.read_bytes()

    mod.main([str(path)])

    assert path.read_bytes() == before


# --------------------------------------------------------------------------------------
# Regression: the two real files the hook is scoped to must actually pass
# --------------------------------------------------------------------------------------


@pytest.mark.parametrize("path", REAL_JSONC_FILES, ids=lambda p: p.name)
def test_real_repo_jsonc_files_pass(mod: ModuleType, path: Path) -> None:
    assert path.exists(), f"{path} is in the hook's files: regex but does not exist"
    assert mod.check_file(path) is None


@pytest.mark.parametrize("path", REAL_JSONC_FILES, ids=lambda p: p.name)
def test_real_repo_jsonc_files_are_genuinely_jsonc(mod: ModuleType, path: Path) -> None:
    """If one of these ever becomes strict JSON, it belongs back under check-json."""
    import json

    with pytest.raises(json.JSONDecodeError):
        json.loads(path.read_text(encoding="utf-8"))
