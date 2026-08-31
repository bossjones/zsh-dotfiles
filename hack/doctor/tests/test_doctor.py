"""Tests for hack/doctor/doctor.py.

Six layers, per specs/migration-doctor.md#testing-strategy:

  1. handler units      - one per check type, fake runner, tmp_path home
  2. resolution         - the five ordered rules, incl. the ambiguity error
  3. schema             - the committed config validates; bad fixtures rejected
  4. state semantics    - today vs target, drift tolerance
  5. traceability       - every traces: entry exists in a spec
  6. live               - real adobetop run, DOCTOR_LIVE=1 only

Handlers are pure with respect to Ctx, so nothing here touches the real system
except layer 6.
"""

from __future__ import annotations

import copy
import importlib.util
import json
import os
import re
import sys
from pathlib import Path

import pytest

DOCTOR_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = DOCTOR_DIR.parent.parent
SCHEMA_PATH = REPO_ROOT / "hack" / "schemas" / "doctor-profiles.schema.json"
PROFILES_PATH = DOCTOR_DIR / "profiles.yaml"

_spec = importlib.util.spec_from_file_location("doctor", DOCTOR_DIR / "doctor.py")
doctor = importlib.util.module_from_spec(_spec)
sys.modules["doctor"] = doctor
_spec.loader.exec_module(doctor)


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------


class FakeRunner:
    """Stubs command execution. Maps a substring of the command to a result."""

    def __init__(self, responses=None, default=(0, "", "")):
        self.responses = responses or {}
        self.default = default
        self.calls = []

    def __call__(self, cmd, cwd=None, timeout=None):
        self.calls.append(cmd)
        for needle, result in self.responses.items():
            if needle in cmd:
                return result
        return self.default


def make_ctx(tmp_path, runner=None, **overrides):
    fields = dict(
        home=tmp_path,
        arch="arm64",
        username="malcolm",
        os="darwin",
        os_major=15,
        hw_model="MacBookPro18,3",
        computer_name="adobetop",
        local_host_name="adobetop",
        host_name=None,
        runner=runner or FakeRunner(),
    )
    fields.update(overrides)
    return doctor.Ctx(**fields)


def check(**kw):
    base = {"id": "t", "title": "t", "type": "command"}
    base.update(kw)
    return doctor.Check.from_dict(base)


MINIMAL_CONFIG = {
    "version": 1,
    "hosts": {
        "adobetop": {
            "identity": {
                "profile": "work",
                "match": {"arch": "arm64", "username": "malcolm"},
            }
        }
    },
}


# --------------------------------------------------------------------------
# layer 3 - schema
# --------------------------------------------------------------------------


class TestSchema:
    def test_committed_profiles_yaml_validates(self):
        cfg = doctor.load_config(PROFILES_PATH)
        assert doctor.validate_config(cfg) == []

    def test_minimal_config_validates(self):
        assert doctor.validate_config(MINIMAL_CONFIG) == []

    def test_hosts_may_not_declare_checks(self):
        """The whole point of the three-layer split: no home for permanent
        per-host assertions."""
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["hosts"]["adobetop"]["checks"] = [
            {"id": "x", "title": "x", "type": "file_exists", "path": "~/x"}
        ]
        errors = doctor.validate_config(cfg)
        assert errors, "hosts.<h>.checks must be rejected"
        assert any("checks" in e for e in errors)

    @pytest.mark.parametrize("missing", ["observed", "expected", "tracked"])
    def test_drift_requires_provenance(self, missing):
        entry = {
            "id": "d", "title": "d", "type": "file_exists", "path": "~/x",
            "observed": "2026-08-15", "expected": "absent", "tracked": "#129",
        }
        del entry[missing]
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["hosts"]["adobetop"]["drift"] = [entry]
        assert doctor.validate_config(cfg), f"drift without {missing} must be rejected"

    def test_tracked_must_look_like_an_issue(self):
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["hosts"]["adobetop"]["drift"] = [{
            "id": "d", "title": "d", "type": "file_exists", "path": "~/x",
            "observed": "2026-08-15", "expected": "absent", "tracked": "soon",
        }]
        assert doctor.validate_config(cfg)

    def test_unknown_check_type_rejected(self):
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["common"] = {"checks": [{"id": "x", "title": "x", "type": "telepathy"}]}
        assert doctor.validate_config(cfg)

    def test_bad_phase_rejected(self):
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["common"] = {"checks": [
            {"id": "x", "title": "x", "type": "file_exists", "path": "~/x",
             "phase": "eventually"}
        ]}
        assert doctor.validate_config(cfg)

    def test_command_without_assertion_rejected(self):
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["common"] = {"checks": [
            {"id": "x", "title": "x", "type": "command", "run": "true"}
        ]}
        assert doctor.validate_config(cfg)

    def test_duplicate_id_across_layers_rejected(self):
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        dup = {"id": "same", "title": "x", "type": "file_exists", "path": "~/x"}
        cfg["common"] = {"checks": [dup]}
        cfg["profiles"] = {"work": {"checks": [copy.deepcopy(dup)]}}
        errors = doctor.validate_config(cfg)
        assert any("same" in e for e in errors), "duplicate id must name the id"

    def test_when_may_not_gate_on_profile(self):
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["common"] = {"checks": [
            {"id": "x", "title": "x", "type": "file_exists", "path": "~/x",
             "when": {"profile": "work"}}
        ]}
        assert doctor.validate_config(cfg)


# --------------------------------------------------------------------------
# layer 2 - profile resolution
# --------------------------------------------------------------------------


AMBIGUOUS = {
    "version": 1,
    "hosts": {
        "supertop": {"identity": {
            "profile": "personal",
            "match": {"arch": "arm64", "username": "bossjones"}}},
        "minitop": {"identity": {
            "profile": "personal",
            "aliases": ["Mac", "mac-mini"],
            "match": {"arch": "arm64", "username": "bossjones"}}},
    },
}


class TestResolution:
    def test_explicit_override_wins_over_hostname(self, tmp_path):
        ctx = make_ctx(tmp_path, local_host_name="minitop", username="bossjones")
        assert doctor.resolve_host(AMBIGUOUS, ctx, override="supertop") == "supertop"

    def test_unknown_override_lists_valid_names(self, tmp_path):
        ctx = make_ctx(tmp_path, username="bossjones")
        with pytest.raises(doctor.ResolutionError) as e:
            doctor.resolve_host(AMBIGUOUS, ctx, override="nonesuch")
        assert "supertop" in str(e.value) and "minitop" in str(e.value)

    def test_env_var_beats_machine_local_file(self, tmp_path, monkeypatch):
        (tmp_path / ".config" / "dotfiles-doctor").mkdir(parents=True)
        (tmp_path / ".config" / "dotfiles-doctor" / "profile").write_text("minitop\n")
        monkeypatch.setenv("DOTFILES_DOCTOR_PROFILE", "supertop")
        ctx = make_ctx(tmp_path, username="bossjones")
        assert doctor.resolve_host(AMBIGUOUS, ctx) == "supertop"

    def test_machine_local_file_used(self, tmp_path, monkeypatch):
        monkeypatch.delenv("DOTFILES_DOCTOR_PROFILE", raising=False)
        (tmp_path / ".config" / "dotfiles-doctor").mkdir(parents=True)
        (tmp_path / ".config" / "dotfiles-doctor" / "profile").write_text("minitop\n")
        ctx = make_ctx(tmp_path, username="bossjones")
        assert doctor.resolve_host(AMBIGUOUS, ctx) == "minitop"

    def test_alias_resolves_stale_hostname(self, tmp_path, monkeypatch):
        """The mini answers to 'Mac' today; it must still find its profile."""
        monkeypatch.delenv("DOTFILES_DOCTOR_PROFILE", raising=False)
        ctx = make_ctx(tmp_path, username="bossjones",
                       computer_name="Mac", local_host_name="Mac")
        assert doctor.resolve_host(AMBIGUOUS, ctx) == "minitop"

    def test_ambiguous_fingerprint_names_all_candidates(self, tmp_path, monkeypatch):
        """supertop and minitop are both arm64/bossjones. Guessing is forbidden."""
        monkeypatch.delenv("DOTFILES_DOCTOR_PROFILE", raising=False)
        ctx = make_ctx(tmp_path, username="bossjones",
                       computer_name="unknown", local_host_name="unknown")
        with pytest.raises(doctor.ResolutionError) as e:
            doctor.resolve_host(AMBIGUOUS, ctx)
        msg = str(e.value)
        assert "supertop" in msg and "minitop" in msg
        assert "--profile" in msg, "must tell the operator how to disambiguate"

    def test_no_match_is_an_error_not_a_silent_pass(self, tmp_path, monkeypatch):
        monkeypatch.delenv("DOTFILES_DOCTOR_PROFILE", raising=False)
        ctx = make_ctx(tmp_path, username="nobody", computer_name="x",
                       local_host_name="x")
        with pytest.raises(doctor.ResolutionError):
            doctor.resolve_host(AMBIGUOUS, ctx)

    def test_unique_fingerprint_resolves(self, tmp_path, monkeypatch):
        monkeypatch.delenv("DOTFILES_DOCTOR_PROFILE", raising=False)
        ctx = make_ctx(tmp_path, computer_name="x", local_host_name="x")
        assert doctor.resolve_host(MINIMAL_CONFIG, ctx) == "adobetop"


# --------------------------------------------------------------------------
# layer 1 - handlers
# --------------------------------------------------------------------------


class TestFileHandlers:
    def test_file_exists_present(self, tmp_path):
        (tmp_path / "f").write_text("x")
        r = doctor.run_check(check(type="file_exists", path="~/f"), make_ctx(tmp_path))
        assert r.status == doctor.PASS

    def test_file_exists_absent_when_wanted_present(self, tmp_path):
        r = doctor.run_check(check(type="file_exists", path="~/nope"), make_ctx(tmp_path))
        assert r.status == doctor.FAIL

    def test_file_exists_want_absent(self, tmp_path):
        r = doctor.run_check(
            check(type="file_exists", path="~/nope", want="absent"), make_ctx(tmp_path))
        assert r.status == doctor.PASS

    def test_file_contains_literal(self, tmp_path):
        (tmp_path / "gi").write_text("a\n**/.claude/settings.local.json\nb\n")
        r = doctor.run_check(
            check(type="file_contains", path="~/gi",
                  want="**/.claude/settings.local.json"), make_ctx(tmp_path))
        assert r.status == doctor.PASS

    def test_file_contains_missing_file_is_failure(self, tmp_path):
        r = doctor.run_check(
            check(type="file_contains", path="~/nope", want="x"), make_ctx(tmp_path))
        assert r.status == doctor.FAIL

    def test_file_contains_absent_inverts(self, tmp_path):
        (tmp_path / "f").write_text("hello\n")
        r = doctor.run_check(
            check(type="file_contains", path="~/f", want="hello", absent=True),
            make_ctx(tmp_path))
        assert r.status == doctor.FAIL

    def test_symlink_compares_raw_link_text(self, tmp_path):
        """M4 expects the RELATIVE link '.vim/.vimrc'; realpath would erase it."""
        (tmp_path / ".vim").mkdir()
        (tmp_path / ".vim" / ".vimrc").write_text("set nocp\n")
        (tmp_path / ".vimrc").symlink_to(".vim/.vimrc")
        r = doctor.run_check(
            check(type="symlink", path="~/.vimrc", target=".vim/.vimrc"),
            make_ctx(tmp_path))
        assert r.status == doctor.PASS

    def test_symlink_regular_file_fails(self, tmp_path):
        (tmp_path / ".vimrc").write_text("x")
        r = doctor.run_check(
            check(type="symlink", path="~/.vimrc", target=".vim/.vimrc"),
            make_ctx(tmp_path))
        assert r.status == doctor.FAIL


class TestCommandHandler:
    def test_want_exit_default_zero(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner(default=(0, "", "")))
        assert doctor.run_check(check(run="true", want_exit=0), ctx).status == doctor.PASS

    def test_stdout_not_matching(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner({"chezmoi": (0, "hub.host = ADOBE\n", "")}))
        r = doctor.run_check(
            check(run="chezmoi cat", want_stdout_not_matching="(?i)adobe"), ctx)
        assert r.status == doctor.FAIL

    def test_stdout_empty(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner(default=(0, "  \n", "")))
        assert doctor.run_check(
            check(run="git diff", want_stdout_empty=True), ctx).status == doctor.PASS

    def test_stderr_matching_for_shell_baseline(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner(
            {"zsh": (0, "", "(eval):1: can't change option: zle\n")}))
        r = doctor.run_check(
            check(run="zsh -i -c exit", want_stderr_matching="can't change option: zle"), ctx)
        assert r.status == doctor.PASS

    def test_assertions_are_anded(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner(default=(1, "ok", "")))
        r = doctor.run_check(
            check(run="x", want_exit=0, want_stdout_matching="ok"), ctx)
        assert r.status == doctor.FAIL


class TestHostnameHandler:
    def test_mismatch_fails(self, tmp_path):
        ctx = make_ctx(tmp_path, computer_name="Mac")
        r = doctor.run_check(
            check(type="hostname", which="computer", want="minitop"), ctx)
        assert r.status == doctor.FAIL
        assert "Mac" in r.message

    def test_unset_host_name_allowed(self, tmp_path):
        """Unset HostName is the macOS default on a healthy machine."""
        ctx = make_ctx(tmp_path, host_name=None)
        r = doctor.run_check(
            check(type="hostname", which="host", want="adobetop",
                  allow_unset=True, severity="warn"), ctx)
        assert r.status in (doctor.PASS, doctor.WARN)
        assert r.status != doctor.FAIL

    def test_unset_not_allowed_fails(self, tmp_path):
        ctx = make_ctx(tmp_path, host_name=None)
        r = doctor.run_check(
            check(type="hostname", which="host", want="adobetop"), ctx)
        assert r.status == doctor.FAIL


class TestChezmoiHandlers:
    def test_chezmoi_data_dotted_key(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner(
            {"chezmoi data": (0, json.dumps({"version_manager": "mise"}), "")}))
        r = doctor.run_check(
            check(type="chezmoi_data", key="version_manager", want="mise"), ctx)
        assert r.status == doctor.PASS

    def test_chezmoi_data_missing_key_fails(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner(
            {"chezmoi data": (0, json.dumps({"cuda": True}), "")}))
        r = doctor.run_check(
            check(type="chezmoi_data", key="profile", want="work"), ctx)
        assert r.status == doctor.FAIL

    def test_chezmoi_data_is_fetched_once(self, tmp_path):
        runner = FakeRunner({"chezmoi data": (0, json.dumps({"a": 1, "b": 2}), "")})
        ctx = make_ctx(tmp_path, runner=runner)
        doctor.run_check(check(type="chezmoi_data", key="a", want=1), ctx)
        doctor.run_check(check(type="chezmoi_data", key="b", want=2), ctx)
        assert sum("chezmoi data" in c for c in runner.calls) == 1

    def test_chezmoi_managed_count(self, tmp_path):
        ctx = make_ctx(tmp_path, runner=FakeRunner(
            {"chezmoi managed": (0, ".gitconfig-adobe-corp\n.gitconfig-adobe-ghec\n"
                                    ".gitconfig-personal\n.zshrc\n", "")}))
        r = doctor.run_check(
            check(type="chezmoi_managed", pattern=r"gitconfig-", count=3), ctx)
        assert r.status == doctor.PASS

    def test_data_complete_flags_missing_keys(self, tmp_path):
        """adobetop's real failure: version_manager/fzf_tab/profile all absent."""
        tmpl = tmp_path / "tmpl"
        tmpl.write_text(
            "data:\n  version_manager: x\n  fzf_tab: y\n  profile: z\n  name: n\n")
        ctx = make_ctx(tmp_path, runner=FakeRunner(
            {"chezmoi data": (0, json.dumps({"name": "Malcolm Jones"}), "")}))
        r = doctor.run_check(
            check(type="chezmoi_data_complete", path=str(tmpl)), ctx)
        assert r.status == doctor.FAIL
        for key in ("version_manager", "fzf_tab", "profile"):
            assert key in r.message


class TestWhenGate:
    def test_when_mismatch_skips(self, tmp_path):
        r = doctor.run_check(
            check(type="file_exists", path="~/x", when={"hw_model": "Macmini.*"}),
            make_ctx(tmp_path, hw_model="MacBookPro18,3"))
        assert r.status == doctor.SKIP

    def test_when_match_runs(self, tmp_path):
        (tmp_path / "x").write_text("")
        r = doctor.run_check(
            check(type="file_exists", path="~/x", when={"os": "darwin"}),
            make_ctx(tmp_path))
        assert r.status == doctor.PASS


# --------------------------------------------------------------------------
# layer 4 - state semantics
# --------------------------------------------------------------------------


DRIFT_CFG = {
    "version": 1,
    "hosts": {
        "adobetop": {
            "identity": {"profile": "work",
                         "match": {"arch": "arm64", "username": "malcolm"}},
            "drift": [{
                "id": "zle-warning", "title": "pre-existing zle warning",
                "type": "file_exists", "path": "~/drifty",
                "observed": "2026-08-15", "expected": "absent", "tracked": "#129",
            }],
        }
    },
}


class TestStateSemantics:
    def test_holding_drift_is_known_under_today(self, tmp_path):
        (tmp_path / "drifty").write_text("")
        results = doctor.run_all(DRIFT_CFG, make_ctx(tmp_path), "adobetop",
                                 phase="always", state="today")
        assert [r.status for r in results] == [doctor.KNOWN]
        assert doctor.exit_code(results) == 0

    def test_same_drift_fails_under_target(self, tmp_path):
        (tmp_path / "drifty").write_text("")
        results = doctor.run_all(DRIFT_CFG, make_ctx(tmp_path), "adobetop",
                                 phase="always", state="target")
        assert [r.status for r in results] == [doctor.FAIL]
        assert doctor.exit_code(results) == 1

    def test_drift_that_stops_holding_is_a_finding(self, tmp_path):
        """The machine moved underneath us -- the register is now wrong."""
        results = doctor.run_all(DRIFT_CFG, make_ctx(tmp_path), "adobetop",
                                 phase="always", state="today")
        assert results[0].status == doctor.FAIL

    def test_phase_and_state_compose(self, tmp_path):
        cfg = copy.deepcopy(DRIFT_CFG)
        cfg["common"] = {"checks": [
            {"id": "pre-only", "title": "p", "type": "file_exists",
             "path": "~/nope", "phase": "pre"}
        ]}
        (tmp_path / "drifty").write_text("")
        results = doctor.run_all(cfg, make_ctx(tmp_path), "adobetop",
                                 phase="post", state="target")
        assert {r.check.id for r in results} == {"zle-warning"}


class TestEffectiveChecks:
    def test_three_layers_merge(self, tmp_path):
        cfg = copy.deepcopy(MINIMAL_CONFIG)
        cfg["common"] = {"checks": [
            {"id": "c", "title": "c", "type": "file_exists", "path": "~/a"}]}
        cfg["profiles"] = {
            "work": {"checks": [
                {"id": "w", "title": "w", "type": "file_exists", "path": "~/b"}]},
            "personal": {"checks": [
                {"id": "p", "title": "p", "type": "file_exists", "path": "~/c"}]},
        }
        ids = {c.id for c in doctor.effective_checks(cfg, "adobetop")}
        assert ids == {"c", "w"}, "personal checks must not leak into a work host"


# --------------------------------------------------------------------------
# layer 5 - traceability
# --------------------------------------------------------------------------


class TestTraceability:
    def test_every_trace_exists_in_a_spec(self):
        specs = "\n".join(
            (REPO_ROOT / "specs" / n).read_text()
            for n in ("unified-dotfiles-gap-analysis.md", "migration-doctor.md"))
        cfg = doctor.load_config(PROFILES_PATH)
        missing = []
        for c in doctor.all_checks(cfg):
            for t in c.traces:
                if re.fullmatch(r"[SMCQ]\d+", t):
                    if not re.search(rf"\b{t}\b", specs):
                        missing.append(f"{c.id} -> {t}")
        assert not missing, f"traces with no matching finding: {missing}"

    def test_issue_traces_are_syntactically_valid(self):
        cfg = doctor.load_config(PROFILES_PATH)
        for c in doctor.all_checks(cfg):
            for t in c.traces:
                assert re.fullmatch(r"[SMCQ]\d+|#\d+", t), f"{c.id}: bad trace {t!r}"


# --------------------------------------------------------------------------
# layer 6 - live
# --------------------------------------------------------------------------


live = pytest.mark.skipif(
    os.environ.get("DOCTOR_LIVE") != "1", reason="set DOCTOR_LIVE=1")


@live
class TestLive:
    def test_identity_works_without_a_resolved_profile(self):
        """Survey machines have no host block yet; --identity must still work."""
        rc, out = doctor.main_capture(["--identity", "--format", "json"])
        assert rc == 0
        payload = json.loads(out)
        assert "computer_name" in payload and "local_host_name" in payload

    def test_validate_passes(self):
        assert doctor.main_capture(["--validate"])[0] == 0
