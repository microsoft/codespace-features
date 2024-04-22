import os

import nox

os.environ.update({"PDM_IGNORE_SAVED_PYTHON": "1"})

PYTHON_VERSIONS = ["3.8", "3.9", "3.10", "3.11", "3.12"]
LOCATIONS = "src", "tests", "noxfile.py"


@nox.session(py=PYTHON_VERSIONS)
@nox.parametrize("keyring", ["20", "25.1"])
@nox.parametrize("pyjwt", ["2.0.0", "2.8"])
def tests(session, keyring, pyjwt):
    session.run_always("pdm", "install", "-G", "test", external=True)
    session.install(f"keyring=={keyring}")
    session.install(f"pyjwt=={pyjwt}")
    session.run("pdm", "test", *session.posargs, external=True)


@nox.session
def lint(session):
    session.run_always("pdm", "install", "-G", "lint", external=True)
    session.run("pdm", "check", external=True)


@nox.session(py=PYTHON_VERSIONS)
def mypy(session):
    session.run_always("pdm", "install", external=True)
    args = session.posargs or LOCATIONS
    session.run("pdm", "run", "mypy", *args, external=True)
