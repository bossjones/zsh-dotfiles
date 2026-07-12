#!/usr/bin/env python3
"""Integration tests for the opt-in fzf-tab completion feature.

Deferred sheldon plugins only run at the first zle prompt, so ``zsh -i -c``
cannot observe them -- every assertion here goes through a real interactive
shell inside tmux, mirroring test_dotfiles.py::TestDotfiles::test_aliases.

The chezmoi ``fzf_tab`` flag surfaces at runtime as ``ZSH_DOTFILES_FZF_TAB``
(exported from dot_zshrc.tmpl); tests skip themselves when the machine's
flag state does not match what they exercise.
"""

import logging
import os
import pathlib
import shutil
import time
import typing as t

import libtmux
import pytest
from libtmux import exc
from libtmux.server import Server
from libtmux.session import Session
from libtmux.test.constants import TEST_SESSION_PREFIX
from libtmux.test.random import get_test_session_name, namer

log_level = os.environ.get("LOG_LEVEL", "INFO")
logging.basicConfig(format="%(asctime)s:%(levelname)s:%(name)s: %(message)s", level=getattr(logging, log_level))
logger = logging.getLogger(__name__)


def is_running_in_docker() -> bool:
    """Detect if running inside a Docker container."""
    if os.path.exists("/.dockerenv"):
        return True
    if os.getenv("DOCKER_CONTAINER") == "1":
        return True
    return False


IN_DOCKER = is_running_in_docker()

FZF_TAB_ENABLED = os.environ.get("ZSH_DOTFILES_FZF_TAB") == "true"

# Seconds to wait for zsh-defer to drain the deferred plugin queue after the
# first prompt renders.
DEFER_DRAIN_SECONDS = 3


@pytest.fixture(scope="function")
def tmux_fake_server(request: pytest.FixtureRequest) -> Server:
    """Returns a new, temporary :class:`libtmux.Server`."""
    t_server = libtmux.Server(socket_name="zsh_dotfiles_fzftab%s" % next(namer))

    def fin() -> None:
        t_server.kill()

    request.addfinalizer(fin)

    return t_server


@pytest.fixture(scope="function")
def tmux_fake_session(
    request: pytest.FixtureRequest, session_params: t.Dict[str, t.Any], tmux_fake_server: Server
) -> Session:
    """Returns a new, temporary :class:`libtmux.Session`."""
    session_name = "bosstest"

    if not tmux_fake_server.has_session(session_name):
        tmux_fake_server.cmd("new-session", "-d", "-s", session_name)

    old_test_sessions = []
    for s in tmux_fake_server.sessions:
        old_name = s.session_name
        if old_name is not None and old_name.startswith(TEST_SESSION_PREFIX):
            old_test_sessions.append(old_name)

    TEST_SESSION_NAME = get_test_session_name(server=tmux_fake_server)

    try:
        session = tmux_fake_server.new_session(session_name=TEST_SESSION_NAME, **session_params)
    except exc.LibTmuxException as e:
        raise e

    session_id = session.session_id
    assert session_id is not None

    try:
        tmux_fake_server.switch_client(target_session=session_id)
    except exc.LibTmuxException:
        pass

    for old_test_session in old_test_sessions:
        logger.debug(f"Old test test session {old_test_session} found. Killing it.")
        tmux_fake_server.kill_session(old_test_session)
    assert TEST_SESSION_NAME == session.session_name
    assert TEST_SESSION_NAME != "bosstest"

    return session


def _spawn_interactive_zsh(
    tmux_fake_session: Session,
    window_name: str,
    extra_env: t.Optional[t.Dict[str, str]] = None,
) -> "libtmux.pane.Pane":
    """Open a real interactive zsh (full ~/.zshrc + sheldon) in a new tmux window
    and wait for the zsh-defer queue to drain."""
    env = shutil.which("env")
    assert env is not None, "Cannot find usable `env` in PATH."

    env_prefix = ""
    if extra_env:
        env_prefix = " ".join(f"{k}={v}" for k, v in extra_env.items()) + " "

    tmux_fake_session.new_window(
        attach=True, window_name=window_name, window_shell=f"{env} {env_prefix}zsh -i"
    )

    time.sleep(DEFER_DRAIN_SECONDS)

    attached_window = tmux_fake_session.active_window
    pane = attached_window.active_pane
    assert pane is not None
    return pane


def _pane_output(pane: "libtmux.pane.Pane", cmd: str, settle: float = 1.0) -> str:
    """Send a command to the pane and return the captured pane contents."""
    pane.send_keys(cmd, enter=True)
    time.sleep(settle)
    return "\n".join(pane.capture_pane())


class TestFzfTab:
    @pytest.mark.flaky()
    @pytest.mark.skipif(IN_DOCKER, reason="Test not supported in Docker container")
    @pytest.mark.skipif(not FZF_TAB_ENABLED, reason="fzf_tab chezmoi flag is off on this machine")
    def test_fzf_tab_binds_tab(self, tmux_fake_session: Session) -> None:
        """With the flag on, fzf-tab must be the last plugin to bind ^I."""
        pane = _spawn_interactive_zsh(tmux_fake_session, "test_fzf_tab_binds_tab")
        pane_contents = _pane_output(pane, "bindkey '^I'")
        assert "fzf-tab-complete" in pane_contents

    @pytest.mark.flaky()
    @pytest.mark.skipif(IN_DOCKER, reason="Test not supported in Docker container")
    @pytest.mark.skipif(not FZF_TAB_ENABLED, reason="fzf_tab chezmoi flag is off on this machine")
    def test_fzf_tab_loads_after_compinit(self, tmux_fake_session: Session) -> None:
        """_fzf-tab-apply only resolves once fzf-tab sourced against a live compsys."""
        pane = _spawn_interactive_zsh(tmux_fake_session, "test_fzf_tab_after_compinit")
        pane_contents = _pane_output(pane, "whence -w _fzf-tab-apply")
        assert "_fzf-tab-apply: function" in pane_contents

    @pytest.mark.flaky()
    @pytest.mark.skipif(IN_DOCKER, reason="Test not supported in Docker container")
    @pytest.mark.skipif(FZF_TAB_ENABLED, reason="fzf_tab chezmoi flag is on on this machine")
    def test_fzf_tab_absent_when_disabled(self, tmux_fake_session: Session) -> None:
        """With the flag off, Tab must stay on stock zsh completion."""
        pane = _spawn_interactive_zsh(tmux_fake_session, "test_fzf_tab_absent")
        pane_contents = _pane_output(pane, "bindkey '^I'")
        assert "fzf-tab-complete" not in pane_contents
        assert '"^I"' in pane_contents

    @pytest.mark.flaky()
    @pytest.mark.skipif(IN_DOCKER, reason="Test not supported in Docker container")
    @pytest.mark.skipif(not FZF_TAB_ENABLED, reason="fzf_tab chezmoi flag is off on this machine")
    def test_fzf_tab_sentinel_skips_sourcing(self, tmux_fake_session: Session, tmp_path: pathlib.Path) -> None:
        """With the persistent-off sentinel present at startup, fzf-tab is never
        sourced -- but the fzf-tab-on helper is still defined."""
        sentinel_dir = tmp_path / "zsh-dotfiles"
        sentinel_dir.mkdir(parents=True)
        (sentinel_dir / "fzf-tab-disabled").touch()

        pane = _spawn_interactive_zsh(
            tmux_fake_session,
            "test_fzf_tab_sentinel",
            extra_env={"XDG_CONFIG_HOME": str(tmp_path)},
        )

        pane_contents = _pane_output(pane, "bindkey '^I'")
        assert "fzf-tab-complete" not in pane_contents

        # The plugin itself must not have been sourced at all.
        pane_contents = _pane_output(pane, "whence -w disable-fzf-tab || echo NOT-SOURCED")
        assert "disable-fzf-tab: function" not in pane_contents
        assert "NOT-SOURCED" in pane_contents

        # The sentinel-backed helpers stay available so the user can re-enable.
        pane_contents = _pane_output(pane, "whence -w fzf-tab-on")
        assert "fzf-tab-on: function" in pane_contents

    @pytest.mark.flaky()
    @pytest.mark.skipif(IN_DOCKER, reason="Test not supported in Docker container")
    @pytest.mark.skipif(not FZF_TAB_ENABLED, reason="fzf_tab chezmoi flag is off on this machine")
    def test_fzf_tab_off_on_roundtrip(self, tmux_fake_session: Session, tmp_path: pathlib.Path) -> None:
        """fzf-tab-off and fzf-tab-on flip ^I and the sentinel together, in-place."""
        sentinel = tmp_path / "zsh-dotfiles" / "fzf-tab-disabled"

        pane = _spawn_interactive_zsh(
            tmux_fake_session,
            "test_fzf_tab_roundtrip",
            extra_env={"XDG_CONFIG_HOME": str(tmp_path)},
        )

        pane_contents = _pane_output(pane, "bindkey '^I'")
        assert "fzf-tab-complete" in pane_contents

        pane_contents = _pane_output(pane, "fzf-tab-off; bindkey '^I'")
        assert sentinel.exists()
        # The most recent bindkey report must no longer be fzf-tab.
        last_bindkey = [line for line in pane_contents.splitlines() if '"^I"' in line][-1]
        assert "fzf-tab-complete" not in last_bindkey

        pane_contents = _pane_output(pane, "fzf-tab-on; bindkey '^I'")
        assert not sentinel.exists()
        last_bindkey = [line for line in pane_contents.splitlines() if '"^I"' in line][-1]
        assert "fzf-tab-complete" in last_bindkey
