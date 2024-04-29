import os
from typing import List

import nox

os.environ.update({"PDM_IGNORE_SAVED_PYTHON": "1"})

DEFAULT_PYTHON_VERSION = "3.11"
PYTHON_VERSIONS: List[str] = ["3.8", "3.9", "3.10", "3.11", "3.12"]

DEFAULT_TEST_LOCATION = "tests"
LOCATIONS = ["src", DEFAULT_TEST_LOCATION, "noxfile.py"]


@nox.session(py=DEFAULT_PYTHON_VERSION, tags=["ci"])
def lint(session):
    """Run the linter.

    Returns a failure if the linter finds any issues.
    """
    session.run_always("pdm", "install", "-dG", "lint", external=True)
    session.run("ruff", "check", *LOCATIONS, *session.posargs)


@nox.session(py=DEFAULT_PYTHON_VERSION, tags=["ci"])
def format_check(session):
    """Run the formatter and fail if issues are found."""
    session.notify("format", posargs=["--check", *LOCATIONS])


@nox.session(py=DEFAULT_PYTHON_VERSION)
def format(session):
    """Run the formatter and fix issues."""
    session.run_always("pdm", "install", "-dG", "lint", external=True)
    args = session.posargs or LOCATIONS
    session.run("ruff", "format", *args)


@nox.session(tags=["ci"])
@nox.parametrize(
    "python,keyring",
    [
        (python, keyring)
        for python in PYTHON_VERSIONS
        for keyring in ("20", "25.1")
        # exclude keyring 20 because it is incompatible with python 3.12
        if (python, keyring) != ("3.12", "20")
    ],
)
def tests(session, keyring):
    """Run the test suite."""
    session.run_always("pdm", "install", "-dG", "test", external=True)
    session.install(f"keyring=={keyring}")
    args = session.posargs or [DEFAULT_TEST_LOCATION]
    session.run("pytest", "-v", *args)


@nox.session(py=PYTHON_VERSIONS, tags=["ci"])
def mypy(session):
    """Run the type checker."""
    session.run_always("pdm", "install", external=True)
    args = session.posargs or LOCATIONS
    session.run("mypy", *args)
