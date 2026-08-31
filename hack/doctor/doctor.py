#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6", "jsonschema>=4"]
# ///
"""A YAML-driven convergence doctor for the zsh-dotfiles fleet.

Answers four questions on any machine:

    which machine am I?            (and is that answer unambiguous?)
    is it safe to migrate?         --phase pre
    did the migration land?        --phase post
    how far from its profile?      --state target

Read-only by construction: every check may carry a `fix:` string, which is
printed and never executed.

Design: specs/migration-doctor.md
"""

from __future__ import annotations

import argparse
import contextlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

HERE = Path(__file__).resolve().parent
DEFAULT_CONFIG = HERE / "profiles.yaml"
DEFAULT_SCHEMA = HERE.parent / "schemas" / "doctor-profiles.schema.json"

PASS, FAIL, WARN, SKIP, KNOWN, ERROR = "PASS", "FAIL", "WARN", "SKIP", "KNOWN", "ERROR"

EXIT_OK, EXIT_FAILED, EXIT_CONFIG, EXIT_RESOLUTION = 0, 1, 2, 3

GLYPH = {PASS: "✓", FAIL: "✗", WARN: "⚠", SKIP: "⊘",
         KNOWN: "●", ERROR: "✗"}


class ConfigError(Exception):
    """profiles.yaml is missing, unparseable, or schema-invalid."""


class ResolutionError(Exception):
    """The host could not be resolved, or resolved ambiguously."""


# ---------------------------------------------------------------------------
# model
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Check:
    id: str
    title: str
    type: str
    phase: str = "always"
    severity: str = "error"
    traces: tuple[str, ...] = ()
    fix: str | None = None
    when: dict[str, Any] = field(default_factory=dict)
    spec: dict[str, Any] = field(default_factory=dict)
    is_drift: bool = False
    tracked: str | None = None
    observed: str | None = None
    expected: str | None = None

    @classmethod
    def from_dict(cls, d: dict[str, Any], is_drift: bool = False) -> "Check":
        return cls(
            id=d["id"], title=d.get("title", d["id"]), type=d["type"],
            phase=d.get("phase", "always"), severity=d.get("severity", "error"),
            traces=tuple(d.get("traces", [])), fix=d.get("fix"),
            when=d.get("when", {}) or {}, spec=d, is_drift=is_drift,
            tracked=d.get("tracked"), observed=d.get("observed"),
            expected=d.get("expected"),
        )

    def get(self, key, default=None):
        return self.spec.get(key, default)


@dataclass(frozen=True)
class Result:
    check: Check
    status: str
    message: str = ""

    @property
    def failed(self) -> bool:
        return self.status in (FAIL, ERROR)


# ---------------------------------------------------------------------------
# context
# ---------------------------------------------------------------------------


@dataclass
class Ctx:
    """Resolved environment plus a command runner.

    Handlers are pure with respect to this object, which is what lets the test
    suite inject a stub and never touch the real system.
    """

    home: Path
    arch: str
    username: str
    os: str
    os_major: int | None = None
    hw_model: str = ""
    computer_name: str | None = None
    local_host_name: str | None = None
    host_name: str | None = None
    runner: Callable[..., tuple[int, str, str]] | None = None
    timeout: int = 10
    shell: str = "/bin/zsh"
    _cache: dict = field(default_factory=dict)

    def run(self, cmd: str, cwd: str | None = None) -> tuple[int, str, str]:
        return self.runner(cmd, cwd=cwd, timeout=self.timeout)

    def expand(self, p: str) -> Path:
        if p.startswith("~/"):
            return self.home / p[2:]
        if p == "~":
            return self.home
        return Path(os.path.expandvars(p))

    def cached(self, key: str, produce):
        if key not in self._cache:
            self._cache[key] = produce()
        return self._cache[key]

    @property
    def chezmoi_data(self) -> dict:
        def produce():
            rc, out, _ = self.run("chezmoi data --format json")
            if rc != 0:
                return {}
            try:
                return json.loads(out)
            except json.JSONDecodeError:
                return {}
        return self.cached("chezmoi_data", produce)

    @property
    def chezmoi_managed(self) -> list[str]:
        def produce():
            rc, out, _ = self.run("chezmoi managed")
            return out.splitlines() if rc == 0 else []
        return self.cached("chezmoi_managed", produce)

    @property
    def interactive_path(self) -> list[str]:
        def produce():
            rc, out, _ = self.run("zsh -i -c 'print -l $path'")
            return out.splitlines() if rc == 0 else []
        return self.cached("ipath", produce)

    @property
    def brew_list(self) -> set[str]:
        def produce():
            rc, out, _ = self.run("brew list --formula -1")
            formulae = set(out.split()) if rc == 0 else set()
            rc, out, _ = self.run("brew list --cask -1")
            return formulae | ({"cask:" + c for c in out.split()} if rc == 0 else set())
        return self.cached("brew", produce)


def _sh(cmd: str, cwd: str | None = None, timeout: int = 10) -> tuple[int, str, str]:
    try:
        p = subprocess.run(cmd, shell=True, capture_output=True, text=True,
                           timeout=timeout, cwd=cwd)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"timed out after {timeout}s"
    except OSError as exc:
        return 127, "", str(exc)


def _scutil(which: str) -> str | None:
    rc, out, _ = _sh(f"scutil --get {which}")
    out = out.strip()
    if rc != 0 or not out or "not set" in out:
        return None
    return out


def probe_identity() -> dict[str, Any]:
    """Every macOS hostname source. Works with no config and no resolved host --
    survey machines have no profile yet."""
    settable = {
        "computer_name": _scutil("ComputerName"),
        "local_host_name": _scutil("LocalHostName"),
        "host_name": _scutil("HostName"),
    }
    derived = {
        "kern_hostname": _sh("sysctl -n kern.hostname")[1].strip() or None,
        "hostname": _sh("hostname")[1].strip() or None,
        "hostname_s": _sh("hostname -s")[1].strip() or None,
        "hostname_f": _sh("hostname -f")[1].strip() or None,
        "uname_n": _sh("uname -n")[1].strip() or None,
        "networksetup": _sh("networksetup -getcomputername")[1].strip() or None,
    }
    named = {v for v in settable.values() if v}
    return {
        **settable,
        "derived": derived,
        "arch": _sh("uname -m")[1].strip(),
        "username": _sh("id -un")[1].strip(),
        "os": _sh("uname -s")[1].strip().lower(),
        "hw_model": _sh("sysctl -n hw.model")[1].strip(),
        "agree": len(named) <= 1,
        "unset": [k for k, v in settable.items() if v is None],
    }


def build_ctx(timeout: int = 10, shell: str = "/bin/zsh") -> Ctx:
    ident = probe_identity()
    rc, out, _ = _sh("sw_vers -productVersion")
    major = None
    if rc == 0 and out.strip():
        with contextlib.suppress(ValueError):
            major = int(out.strip().split(".")[0])
    return Ctx(
        home=Path.home(), arch=ident["arch"], username=ident["username"],
        os=ident["os"], os_major=major, hw_model=ident["hw_model"],
        computer_name=ident["computer_name"],
        local_host_name=ident["local_host_name"], host_name=ident["host_name"],
        runner=_sh, timeout=timeout, shell=shell,
    )


# ---------------------------------------------------------------------------
# config
# ---------------------------------------------------------------------------


def load_config(path: Path | str) -> dict:
    import yaml
    path = Path(path)
    if not path.exists():
        raise ConfigError(f"config not found: {path}")
    try:
        data = yaml.safe_load(path.read_text())
    except yaml.YAMLError as exc:
        raise ConfigError(f"{path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ConfigError(f"{path}: top level must be a mapping")
    return data


def validate_config(cfg: dict, schema_path: Path = DEFAULT_SCHEMA) -> list[str]:
    """Return a list of human-readable errors; empty means valid."""
    import jsonschema

    try:
        schema = json.loads(Path(schema_path).read_text())
    except OSError as exc:
        return [f"schema unreadable: {exc}"]

    validator = jsonschema.Draft202012Validator(schema)
    errors = [
        f"{'/'.join(str(p) for p in e.absolute_path) or '<root>'}: {e.message}"
        for e in sorted(validator.iter_errors(cfg), key=lambda e: list(e.absolute_path))
    ]

    # Cross-layer invariants JSON Schema cannot express on its own.
    seen: dict[str, str] = {}
    for where, c in _iter_raw_checks(cfg):
        cid = c.get("id")
        if not cid:
            continue
        if cid in seen:
            errors.append(f"duplicate check id {cid!r} in {where} and {seen[cid]}")
        else:
            seen[cid] = where

    for host, block in (cfg.get("hosts") or {}).items():
        ident = (block or {}).get("identity") or {}
        prof = ident.get("profile")
        if prof and prof not in (cfg.get("profiles") or {}) and cfg.get("profiles"):
            errors.append(f"hosts/{host}: profile {prof!r} has no profiles.{prof} block")

    return errors


def _iter_raw_checks(cfg: dict):
    for c in ((cfg.get("common") or {}).get("checks") or []):
        yield "common", c
    for name, block in (cfg.get("profiles") or {}).items():
        for c in ((block or {}).get("checks") or []):
            yield f"profiles/{name}", c
    for name, block in (cfg.get("hosts") or {}).items():
        for c in ((block or {}).get("drift") or []):
            yield f"hosts/{name}/drift", c


def all_checks(cfg: dict) -> list[Check]:
    out = []
    for where, c in _iter_raw_checks(cfg):
        out.append(Check.from_dict(c, is_drift="/drift" in where))
    return out


def effective_checks(cfg: dict, host: str) -> list[Check]:
    """common + profiles.<resolved> + hosts.<host>.drift.

    There is deliberately no hosts.<h>.checks -- see specs/migration-doctor.md.
    """
    block = (cfg.get("hosts") or {}).get(host)
    if block is None:
        raise ResolutionError(f"unknown host {host!r}")
    profile = (block.get("identity") or {}).get("profile")

    checks = [Check.from_dict(c)
              for c in ((cfg.get("common") or {}).get("checks") or [])]
    pblock = (cfg.get("profiles") or {}).get(profile) or {}
    checks += [Check.from_dict(c) for c in (pblock.get("checks") or [])]
    checks += [Check.from_dict(c, is_drift=True) for c in (block.get("drift") or [])]
    return checks


# ---------------------------------------------------------------------------
# resolution
# ---------------------------------------------------------------------------


def resolve_host(cfg: dict, ctx: Ctx, override: str | None = None) -> str:
    hosts = cfg.get("hosts") or {}
    names = sorted(hosts)

    def known(name, source):
        if name not in hosts:
            raise ResolutionError(
                f"unknown host {name!r} (from {source}).\n  Valid: {', '.join(names)}")
        return name

    if override:
        return known(override, "--profile")

    env = os.environ.get("DOTFILES_DOCTOR_PROFILE")
    if env:
        return known(env.strip(), "$DOTFILES_DOCTOR_PROFILE")

    pinfile = ctx.home / ".config" / "dotfiles-doctor" / "profile"
    if pinfile.exists():
        pinned = pinfile.read_text().strip()
        if pinned:
            return known(pinned, str(pinfile))

    live = {n for n in (ctx.computer_name, ctx.local_host_name, ctx.host_name) if n}
    for name, block in hosts.items():
        ident = (block or {}).get("identity") or {}
        if live & ({name} | set(ident.get("aliases") or [])):
            return name

    candidates = []
    for name, block in hosts.items():
        m = ((block or {}).get("identity") or {}).get("match") or {}
        if m and all(getattr(ctx, k, None) == v for k, v in m.items()):
            candidates.append(name)

    if len(candidates) == 1:
        return candidates[0]

    if not candidates:
        raise ResolutionError(
            "Cannot resolve profile: no host matches this machine.\n"
            f"  arch={ctx.arch} username={ctx.username} "
            f"names={sorted(live) or '(none)'}\n"
            f"  Known hosts: {', '.join(names)}\n"
            "  Pin one with:  doctor.py --profile <name>")

    detail = "\n".join(
        f"    {n:<10} " + ", ".join(
            f"{k}={v}" for k, v in
            (((hosts[n].get("identity") or {}).get("match") or {}).items()))
        for n in candidates)
    first = candidates[0]
    raise ResolutionError(
        f"Cannot resolve profile: {len(candidates)} candidates match this "
        f"machine's fingerprint\n{detail}\n\n"
        "  Disambiguate by any of:\n"
        f"    sudo scutil --set ComputerName {first} && "
        f"sudo scutil --set LocalHostName {first}\n"
        f"    echo {first} > ~/.config/dotfiles-doctor/profile\n"
        f"    doctor.py --profile {first}")


# ---------------------------------------------------------------------------
# handlers
# ---------------------------------------------------------------------------


CHECK_TYPES: dict[str, Callable[[Check, Ctx], Result]] = {}


def register(name):
    def deco(fn):
        CHECK_TYPES[name] = fn
        return fn
    return deco


def _ok(c, msg=""):
    return Result(c, PASS, msg)


def _no(c, msg):
    return Result(c, FAIL, msg)


def _verdict(c, ok: bool, msg: str):
    return _ok(c, msg) if ok else _no(c, msg)


@register("command")
def _h_command(c: Check, ctx: Ctx) -> Result:
    rc, out, err = ctx.run(c.get("run"), cwd=c.get("cwd"))
    checks = []
    if "want_exit" in c.spec:
        checks.append((rc == c.get("want_exit"), f"exit {rc}, want {c.get('want_exit')}"))
    if "want_stdout" in c.spec:
        checks.append((out.strip() == c.get("want_stdout"),
                       f"stdout {out.strip()!r}"))
    if "want_stdout_matching" in c.spec:
        checks.append((re.search(c.get("want_stdout_matching"), out) is not None,
                       f"stdout does not match {c.get('want_stdout_matching')!r}"))
    if "want_stdout_not_matching" in c.spec:
        m = re.search(c.get("want_stdout_not_matching"), out)
        checks.append((m is None,
                       f"stdout matched {c.get('want_stdout_not_matching')!r}"
                       + (f" at {m.group(0)!r}" if m else "")))
    if "want_stdout_empty" in c.spec:
        checks.append((bool(out.strip()) != c.get("want_stdout_empty"),
                       f"stdout {'not ' if c.get('want_stdout_empty') else ''}empty"))
    if "want_stderr_matching" in c.spec:
        checks.append((re.search(c.get("want_stderr_matching"), err) is not None,
                       f"stderr does not match {c.get('want_stderr_matching')!r}"))
    if "want_stderr_not_matching" in c.spec:
        checks.append((re.search(c.get("want_stderr_not_matching"), err) is None,
                       f"stderr matched {c.get('want_stderr_not_matching')!r}"))
    failures = [m for ok, m in checks if not ok]
    return _verdict(c, not failures, "; ".join(failures))


@register("file_exists")
def _h_file_exists(c: Check, ctx: Ctx) -> Result:
    p = ctx.expand(c.get("path"))
    present = p.exists() or p.is_symlink()
    want_present = c.get("want", "present") == "present"
    return _verdict(c, present == want_present,
                    f"{p} {'exists' if present else 'is absent'}")


@register("file_contains")
def _h_file_contains(c: Check, ctx: Ctx) -> Result:
    p = ctx.expand(c.get("path"))
    if not p.exists():
        return _no(c, f"{p} does not exist")
    text = p.read_text(errors="replace")
    if c.get("want_matching"):
        found = re.search(c.get("want_matching"), text) is not None
        what = c.get("want_matching")
    else:
        found = c.get("want") in text
        what = c.get("want")
    return _verdict(c, found != bool(c.get("absent", False)),
                    f"{what!r} {'found' if found else 'not found'} in {p}")


@register("symlink")
def _h_symlink(c: Check, ctx: Ctx) -> Result:
    p = ctx.expand(c.get("path"))
    if c.get("want", "present") == "absent":
        return _verdict(c, not p.is_symlink(), f"{p} is a symlink")
    if not p.is_symlink():
        kind = "a regular file" if p.exists() else "absent"
        return _no(c, f"{p} is {kind}, want a symlink")
    raw = os.readlink(p)  # raw link text -- realpath would erase relativeness
    if c.get("target") is not None:
        return _verdict(c, raw == c.get("target"),
                        f"-> {raw!r}, want {c.get('target')!r}")
    if c.get("target_matching"):
        return _verdict(c, re.search(c.get("target_matching"), raw) is not None,
                        f"-> {raw!r}")
    return _ok(c, f"-> {raw}")


@register("binary")
def _h_binary(c: Check, ctx: Ctx) -> Result:
    path = shutil.which(c.get("name"))
    if c.get("want", "present") == "absent":
        return _verdict(c, path is None, f"{c.get('name')} found at {path}")
    if not path:
        return _no(c, f"{c.get('name')} not on PATH")
    if c.get("in_dir") and not path.startswith(str(ctx.expand(c.get("in_dir")))):
        return _no(c, f"{c.get('name')} at {path}, want under {c.get('in_dir')}")
    if c.get("version_matching"):
        _, out, _ = ctx.run(f"{c.get('name')} {c.get('version_arg', '--version')}")
        if not re.search(c.get("version_matching"), out):
            return _no(c, f"version {out.strip().splitlines()[:1]} "
                          f"does not match {c.get('version_matching')!r}")
    return _ok(c, path)


@register("path_entry")
def _h_path_entry(c: Check, ctx: Ctx) -> Result:
    target = str(ctx.expand(c.get("dir")))
    present = target in ctx.interactive_path
    return _verdict(c, present == (c.get("want", "present") == "present"),
                    f"{target} {'in' if present else 'not in'} interactive $path")


@register("git_config")
def _h_git_config(c: Check, ctx: Ctx) -> Result:
    cwd = c.get("cwd")
    if cwd:
        d = ctx.expand(cwd)
        if not d.is_dir():
            return Result(c, SKIP, f"probe dir {d} does not exist")
        cwd = str(d)
    rc, out, _ = ctx.run(f"git config --get {c.get('key')}", cwd=cwd)
    val = out.strip()
    if c.get("absent"):
        return _verdict(c, rc != 0 or not val, f"{c.get('key')} = {val!r}")
    if rc != 0 or not val:
        return _no(c, f"{c.get('key')} unset")
    if c.get("want_matching"):
        return _verdict(c, re.search(c.get("want_matching"), val) is not None,
                        f"{c.get('key')} = {val!r}")
    return _verdict(c, val == str(c.get("want")),
                    f"{c.get('key')} = {val!r}, want {c.get('want')!r}")


def _dig(data: dict, dotted: str):
    cur: Any = data
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None, False
        cur = cur[part]
    return cur, True


@register("chezmoi_data")
def _h_chezmoi_data(c: Check, ctx: Ctx) -> Result:
    val, found = _dig(ctx.chezmoi_data, c.get("key"))
    if not found:
        return _no(c, f"key {c.get('key')!r} absent from chezmoi data "
                      "(re-run `chezmoi init` -- hasKey is false, so the prompt fires)")
    if c.get("want_matching"):
        return _verdict(c, re.search(c.get("want_matching"), str(val)) is not None,
                        f"{c.get('key')} = {val!r}")
    return _verdict(c, val == c.get("want"),
                    f"{c.get('key')} = {val!r}, want {c.get('want')!r}")


@register("chezmoi_managed")
def _h_chezmoi_managed(c: Check, ctx: Ctx) -> Result:
    n = sum(1 for line in ctx.chezmoi_managed if re.search(c.get("pattern"), line))
    if "count" in c.spec:
        return _verdict(c, n == c.get("count"), f"{n} matches, want {c.get('count')}")
    ok = True
    if "min" in c.spec:
        ok = ok and n >= c.get("min")
    if "max" in c.spec:
        ok = ok and n <= c.get("max")
    return _verdict(c, ok, f"{n} matches")


@register("chezmoi_data_complete")
def _h_data_complete(c: Check, ctx: Ctx) -> Result:
    """Catch the whole 'a flag was added after your last apply' class."""
    tmpl = ctx.expand(c.get("path", "~/.local/share/chezmoi/home/.chezmoi.yaml.tmpl"))
    if not tmpl.exists():
        return Result(c, SKIP, f"{tmpl} not found")
    declared, in_data = [], False
    for line in tmpl.read_text().splitlines():
        if re.match(r"^\s*data:\s*$", line):
            in_data = True
            continue
        if in_data:
            m = re.match(r"^\s{2,}([A-Za-z_][A-Za-z0-9_]*):", line)
            if m:
                declared.append(m.group(1))
            elif line.strip() and not line.startswith((" ", "\t")):
                break
    live = ctx.chezmoi_data
    missing = [k for k in declared if k not in live]
    if not missing:
        return _ok(c, f"{len(declared)} declared keys all present")
    return _no(c, "missing from chezmoi data: " + ", ".join(missing)
                  + " -- re-run `chezmoi init` (hasKey false ⇒ the prompt fires)")


@register("hostname")
def _h_hostname(c: Check, ctx: Ctx) -> Result:
    attr = {"computer": "computer_name", "local": "local_host_name",
            "host": "host_name"}[c.get("which")]
    val = getattr(ctx, attr)
    if val is None:
        if c.get("allow_unset"):
            return _ok(c, "not set (allowed; macOS default)")
        return _no(c, "not set")
    if c.get("want_any_of"):
        return _verdict(c, val in c.get("want_any_of"), f"is {val!r}")
    return _verdict(c, val == c.get("want"), f"want {c.get('want')!r}, got {val!r}")


@register("brew")
def _h_brew(c: Check, ctx: Ctx) -> Result:
    name = c.get("formula") or ("cask:" + c.get("cask"))
    present = name in ctx.brew_list
    return _verdict(c, present == (c.get("want", "present") == "present"),
                    f"{name} {'installed' if present else 'not installed'}")


# ---------------------------------------------------------------------------
# execution
# ---------------------------------------------------------------------------


def _when_matches(c: Check, ctx: Ctx) -> tuple[bool, str]:
    for key, want in c.when.items():
        if key == "binary_present":
            if not shutil.which(want):
                return False, f"when.binary_present={want} absent"
        elif key == "file_present":
            if not ctx.expand(want).exists():
                return False, f"when.file_present={want} absent"
        elif key == "hw_model":
            if not re.search(want, ctx.hw_model or ""):
                return False, f"when.hw_model={want!r}, this host is {ctx.hw_model}"
        else:
            if getattr(ctx, key, None) != want:
                return False, f"when.{key}={want!r}, this host is " \
                              f"{getattr(ctx, key, None)!r}"
    return True, ""


def run_check(c: Check, ctx: Ctx) -> Result:
    ok, why = _when_matches(c, ctx)
    if not ok:
        return Result(c, SKIP, why)
    handler = CHECK_TYPES.get(c.type)
    if handler is None:
        return Result(c, ERROR, f"no handler for type {c.type!r}")
    try:
        r = handler(c, ctx)
    except Exception as exc:  # a broken check must not abort the run
        return Result(c, ERROR, f"{type(exc).__name__}: {exc}")
    if r.status == FAIL and c.severity == "warn":
        return Result(c, WARN, r.message)
    return r


def run_all(cfg: dict, ctx: Ctx, host: str, phase: str = "always",
            state: str = "today") -> list[Result]:
    results = []
    for c in effective_checks(cfg, host):
        if phase != "all" and c.phase != phase and c.phase != "always":
            continue
        if phase == "always" and c.phase != "always":
            continue
        r = run_check(c, ctx)
        if c.is_drift:
            r = _drift_verdict(c, r, state)
        results.append(r)
    return results


def _drift_verdict(c: Check, r: Result, state: str) -> Result:
    """A drift assertion describes the deviation AS IT EXISTS TODAY.

    It passing means the drift is still there:
      - today  -> KNOWN  (accepted; it has a tracking issue)
      - target -> FAIL   (not yet eliminated)
    It failing means the machine moved underneath us, which is its own finding.
    """
    if r.status in (SKIP, ERROR):
        return r
    if r.status == PASS:
        if state == "target":
            return Result(c, FAIL, f"drift not yet resolved ({c.tracked}); "
                                   f"expected {c.expected!r}")
        return Result(c, KNOWN, f"{c.tracked} since {c.observed}")
    return Result(c, FAIL,
                  f"drift register is stale: {c.id} no longer holds "
                  f"({r.message}). Update or delete the entry.")


def exit_code(results: list[Result]) -> int:
    return EXIT_FAILED if any(r.failed for r in results) else EXIT_OK


# ---------------------------------------------------------------------------
# rendering
# ---------------------------------------------------------------------------


def render_text(results: list[Result], host: str, profile: str, how: str,
                phase: str, state: str) -> str:
    buf = io.StringIO()
    w = buf.write
    w(f"Host:    {host}    (resolved by: {how})\n")
    w(f"Profile: {profile}    state={state}  phase={phase}\n\n")
    for r in results:
        w(f"  {GLYPH[r.status]} {r.status:<6} {r.check.id:<32} {r.message}\n")
        if r.failed:
            if r.check.traces:
                w(f"           traces: {', '.join(r.check.traces)}\n")
            if r.check.fix:
                for line in r.check.fix.strip().splitlines():
                    w(f"           fix:    {line}\n")
    tally = {s: sum(1 for r in results if r.status == s)
             for s in (PASS, FAIL, WARN, SKIP, KNOWN, ERROR)}
    w("\n" + " · ".join(f"{v} {k.lower()}" for k, v in tally.items() if v) + "\n")
    return buf.getvalue()


def render_json(results: list[Result], host: str, profile: str, phase: str,
                state: str) -> str:
    return json.dumps({
        "host": host, "profile": profile, "phase": phase, "state": state,
        "results": [{
            "id": r.check.id, "title": r.check.title, "status": r.status,
            "severity": r.check.severity, "message": r.message,
            "traces": list(r.check.traces), "tracked": r.check.tracked,
            "fix": r.check.fix,
        } for r in results],
    }, indent=2)


# ---------------------------------------------------------------------------
# cli
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="doctor.py", description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--config", default=str(DEFAULT_CONFIG))
    p.add_argument("--profile", help="override host resolution")
    p.add_argument("--phase", default="always",
                   choices=["pre", "post", "always", "all"])
    p.add_argument("--state", default="today", choices=["today", "target"])
    p.add_argument("--format", default="text", choices=["text", "json"])
    p.add_argument("--only", help="comma-separated check ids")
    p.add_argument("--skip", help="comma-separated check ids")
    p.add_argument("--validate", action="store_true",
                   help="schema-check the config and exit; run nothing")
    p.add_argument("--identity", action="store_true",
                   help="probe every hostname source; needs no resolved host")
    p.add_argument("--list-profiles", action="store_true")
    p.add_argument("--drift", action="store_true", help="show only the drift register")
    p.add_argument("--explain", metavar="ID")
    p.add_argument("--dry-run", action="store_true")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    # --identity must work before any host block exists: survey machines are
    # not in profiles.yaml yet, and that is exactly when it is most useful.
    if args.identity:
        ident = probe_identity()
        if args.format == "json":
            print(json.dumps(ident, indent=2))
        else:
            print("settable (authoritative):")
            for k in ("computer_name", "local_host_name", "host_name"):
                print(f"  {k:<18} {ident[k] or '(not set)'}")
            print("derived:")
            for k, v in ident["derived"].items():
                print(f"  {k:<18} {v or '(none)'}")
            print(f"\narch={ident['arch']} user={ident['username']} "
                  f"model={ident['hw_model']}")
            if not ident["agree"]:
                print("\n⚠ settable names DISAGREE -- fix before relying on "
                      "hostname-conditional templates")
        return EXIT_OK

    try:
        cfg = load_config(args.config)
    except ConfigError as exc:
        print(f"✗ {exc}", file=sys.stderr)
        return EXIT_CONFIG

    errors = validate_config(cfg)
    if errors:
        print(f"✗ {args.config} is invalid:", file=sys.stderr)
        for e in errors:
            print(f"    {e}", file=sys.stderr)
        return EXIT_CONFIG
    if args.validate:
        n = len(all_checks(cfg))
        print(f"✓ {args.config} valid  ({n} checks, "
              f"{len(cfg.get('hosts') or {})} hosts)")
        return EXIT_OK

    ctx = build_ctx(timeout=(cfg.get("defaults") or {}).get("timeout", 10),
                    shell=(cfg.get("defaults") or {}).get("shell", "/bin/zsh"))

    if args.list_profiles:
        for name, block in sorted((cfg.get("hosts") or {}).items()):
            ident = (block or {}).get("identity") or {}
            flag = " (hypothesis)" if ident.get("hypothesis") else ""
            print(f"  {name:<12} profile={ident.get('profile')}{flag}")
        return EXIT_OK

    try:
        host = resolve_host(cfg, ctx, args.profile)
    except ResolutionError as exc:
        print(f"✗ {exc}", file=sys.stderr)
        return EXIT_RESOLUTION

    profile = ((cfg["hosts"][host].get("identity")) or {}).get("profile", "?")
    how = "--profile" if args.profile else "auto"

    if args.explain:
        for c in effective_checks(cfg, host):
            if c.id == args.explain:
                print(json.dumps(c.spec, indent=2))
                return EXIT_OK
        print(f"✗ no check with id {args.explain!r}", file=sys.stderr)
        return EXIT_CONFIG

    checks = effective_checks(cfg, host)
    if args.drift:
        checks = [c for c in checks if c.is_drift]
    if args.only:
        want = set(args.only.split(","))
        checks = [c for c in checks if c.id in want]
    if args.skip:
        nope = set(args.skip.split(","))
        checks = [c for c in checks if c.id not in nope]

    if args.dry_run:
        for c in checks:
            print(f"  {c.phase:<7} {c.severity:<5} {c.id}")
        return EXIT_OK

    sub = {"version": 1, "hosts": {host: {"identity": {"profile": profile}}}}
    sub["common"] = {"checks": [c.spec for c in checks if not c.is_drift]}
    sub["hosts"][host]["drift"] = [c.spec for c in checks if c.is_drift]
    results = run_all(sub, ctx, host, phase=args.phase, state=args.state)

    if args.format == "json":
        print(render_json(results, host, profile, args.phase, args.state))
    else:
        print(render_text(results, host, profile, how, args.phase, args.state))
    return exit_code(results)


def main_capture(argv: list[str]) -> tuple[int, str]:
    """Run main() and capture stdout -- used by the live tests."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = main(argv)
    return rc, buf.getvalue()


if __name__ == "__main__":
    sys.exit(main())
