#!/usr/bin/env python3

import shutil
import concurrent.futures
import logging
import os
from random import sample
from typing import List
import time

import pytest
import libtmux
import random

import typing as t
from libtmux.server import Server
from libtmux import exc
from libtmux.test import TEST_SESSION_PREFIX, get_test_session_name, namer
from libtmux.session import Session


if t.TYPE_CHECKING:
    from libtmux.session import Session

log_level = os.environ.get("LOG_LEVEL", "INFO")
logging.basicConfig(format="%(asctime)s:%(levelname)s:%(name)s: %(message)s", level=getattr(logging, log_level))
logger = logging.getLogger(__name__)


class RandomStrSequence:
    def __init__(
        self, characters: str = "abcdefghijklmnopqrstuvwxyz0123456789_"
    ) -> None:
        """Create a random letter / number generator. 8 chars in length.

        >>> rng = RandomStrSequence()
        >>> next(rng)
        '...'
        >>> len(next(rng))
        8
        >>> type(next(rng))
        <class 'str'>
        """
        self.characters: str = characters

    def __iter__(self) -> "RandomStrSequence":
        return self

    def __next__(self) -> str:
        return "".join(random.sample(self.characters, k=8))

# namer = RandomStrSequence()

@pytest.fixture(scope="module")
def tmux_client() -> libtmux.server.Server:
    return libtmux.Server()



@pytest.fixture(scope="function")
def tmux_fake_server(
    request: pytest.FixtureRequest,
    monkeypatch: pytest.MonkeyPatch,
    # config_file: pathlib.Path,
) -> libtmux.server.Server:
    """Returns a new, temporary :class:`libtmux.Server`

    >>> from libtmux.server import Server

    >>> def test_example(server: Server) -> None:
    ...     assert isinstance(server, Server)
    ...     session = server.new_session('my session')
    ...     assert len(server.sessions) == 1
    ...     assert [session.name.startswith('my') for session in server.sessions]

    .. ::
        >>> locals().keys()
        dict_keys(...)

        >>> source = ''.join([e.source for e in request._pyfuncitem.dtest.examples][:3])
        >>> pytester = request.getfixturevalue('pytester')

        >>> pytester.makepyfile(**{'whatever.py': source})
        PosixPath(...)

        >>> result = pytester.runpytest('whatever.py', '--disable-warnings')
        ===...

        >>> result.assert_outcomes(passed=1)
    """
    t = libtmux.Server(socket_name="zsh_dotfiles_test%s" % next(namer))

    def fin() -> None:
        t.kill_server()

    request.addfinalizer(fin)

    return t



@pytest.fixture(scope="function")
def tmux_fake_session(
    request: pytest.FixtureRequest, session_params: t.Dict[str, t.Any], tmux_fake_server: Server
) -> "libtmux.Session":
    """Returns a new, temporary :class:`libtmux.Session`

    >>> from libtmux.session import Session

    >>> def test_example(session: "Session") -> None:
    ...     assert isinstance(session.name, str)
    ...     assert session.name.startswith('libtmux_')
    ...     window = session.new_window(window_name='new one')
    ...     assert window.name == 'new one'

    .. ::
        >>> locals().keys()
        dict_keys(...)

        >>> source = ''.join([e.source for e in request._pyfuncitem.dtest.examples][:3])
        >>> pytester = request.getfixturevalue('pytester')

        >>> pytester.makepyfile(**{'whatever.py': source})
        PosixPath(...)

        >>> result = pytester.runpytest('whatever.py', '--disable-warnings')
        ===...

        >>> result.assert_outcomes(passed=1)
    """
    session_name = "bosstest"

    if not tmux_fake_server.has_session(session_name):
        tmux_fake_server.cmd("new-session", "-d", "-s", session_name)

    # find current sessions prefixed with bosstest
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

    """
    Make sure that bosstest can :ref:`test_builder_visually` and switches to
    the newly created session for that testcase.
    """
    session_id = session.session_id
    assert session_id is not None

    try:
        tmux_fake_server.switch_client(target_session=session_id)
    except exc.LibTmuxException:
        # server.attach_session(session.get('session_id'))
        pass

    for old_test_session in old_test_sessions:
        logger.debug(f"Old test test session {old_test_session} found. Killing it.")
        tmux_fake_server.kill_session(old_test_session)
    assert TEST_SESSION_NAME == session.session_name
    assert TEST_SESSION_NAME != "bosstest"

    return session

class TestDotfiles:
    @pytest.mark.skipif(
        os.getenv("GITHUB_ACTOR"),
        reason="These tests are meant to only run locally on laptop prior to porting it over to new system",
    )
    def test_pure_prompt(self, tmux_fake_session: Session) -> None:
        """Verify pure prompt is initialized

        """
        env = shutil.which("env")
        assert env is not None, "Cannot find usable `env` in PATH."


        tmux_fake_session.new_window(attach=True, window_name="test_pure_prompt", window_shell=f"{env} PURE_PROMPT_SYMBOL='>' zsh")

        # takes a couple seconds to start up
        time.sleep(5)

        # get current window
        attached_window = tmux_fake_session.attached_window
        pane = attached_window.attached_pane
        assert pane is not None

        pane.enter()
        pane_contents = "\n".join(pane.capture_pane())
        assert ">" in pane_contents

        # pane.send_keys(r'printf "%s"', literal=True, suppress_history=False)
        # pane_contents = "\n".join(pane.capture_pane())
        # assert pane_contents == '> printf "%s"\n>'

        pane.send_keys("clear -x", literal=True, suppress_history=False)
        pane_contents = "\n".join(pane.capture_pane())

        assert '>' in pane_contents


    def test_aliases(self, tmux_fake_session: Session) -> None:
        """Verify aliases are set correctly


        > typeset -f dl-hls
        dl-hls () {
                pyenv activate yt-dlp3 || true
                yt-dlp -S 'res:500' --downloader ffmpeg -o $(uuidgen).mp4 --cookies=~/Downloads/yt-cookies.txt ${1}
        }


        """
        env = shutil.which("env")
        assert env is not None, "Cannot find usable `env` in PATH."


        tmux_fake_session.new_window(attach=True, window_name="test_pure_prompt", window_shell=f"{env} PURE_PROMPT_SYMBOL='>' zsh")

        # takes a couple seconds to start up
        time.sleep(5)

        attached_window: libtmux.window.Window = tmux_fake_session.attached_window
        attached_window.select_layout("main-vertical")

        attached_window.set_window_option("main-pane-height", 80)
        assert attached_window.show_window_option("main-pane-height") == 80


        # get current window
        pane: libtmux.pane.Pane = attached_window.attached_pane
        assert pane is not None
        pane.clear()
        pane.resize_pane(height=60)
        pane.set_height(60)
        pane.set_width(60)

        pane.enter()
        time.sleep(3)

        pane.send_keys("clear -x", literal=True, suppress_history=False)
        time.sleep(3)
        pane_contents = "\n".join(pane.capture_pane())
        assert '>' in pane_contents

        pane.send_keys('typeset -f dl-hls\n', literal=True, suppress_history=False)
        pane_contents = "\n".join(pane.capture_pane())

        # TODO: Figure out how to expand width of pane to fit output
        expected_contents = """> typeset -f dl-hls
dl-hls () {
        pyenv activate yt-dlp3 || true
        yt-dlp -S 'res:500' --downloader ffmpeg -o $(uuidgen).mp4 --cookies=~/Do
wnloads/yt-cookies.txt ${1}
}"""
        assert expected_contents in pane_contents
