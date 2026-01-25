"""Conftest.py (root-level)

We keep this in root pytest fixtures in pytest's doctest plugin to be available, as well
as avoiding conftest.py from being included in the wheel, in addition to pytest_plugin
for pytester only being available via the root directory.

See "pytest_plugins in non-top-level conftest files" in
https://docs.pytest.org/en/stable/deprecations.html
"""
import pathlib
import shutil
import typing as t

import pytest
from _pytest.doctest import DoctestItem

from libtmux.pytest_plugin import USING_ZSH

if t.TYPE_CHECKING:
    from libtmux.session import Session

pytest_plugins = ["pytester"]


@pytest.fixture(autouse=True, scope="session")
def setup(
    request: pytest.FixtureRequest,
    # config_file: pathlib.Path,
) -> None:
    if USING_ZSH:
        # request.getfixturevalue("zshrc")
        pass


@pytest.fixture(autouse=True, scope="function")
def setup_function(clear_env: pytest.FixtureRequest) -> None:
    """Ensure clean environment for each test function.

    This fixture automatically runs before each test to clear environment
    variables via the clear_env fixture from libtmux.
    """
    pass
