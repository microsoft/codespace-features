# codespaces artifacts helper keyring

wow what a long package name. i'm open to suggestions for renaming it.

## what is this?

The codespaces artifacts helper keyring is a package that provides a keyring implementation for the codespaces artifacts helper at https://github.com/microsoft/ado-codespaces-auth. When the keyring package and this keyring are both installed, pip will automatically use this keyring to store and retrieve credentials when accessing ADO package feeds.

## build instructins

This package uses `pyproject.toml`, and `pdm` for building. To build the package, run the following commands:

```sh
cd src/artifacts-helper/codespaces_artifacts_helper_keyring

# PDM is used to manage the project
$ pip install 'pdm>=2.14'

# Install dependencies and build the package
$ pdm build

# Install package + deps with pip
$ pip install dist/codespaces_artifacts_helper_keyring-*.whl
```

## contributing

```sh
# Lint
$ pdm run check

# Format
$ pdm run fmt

# Type check
$ pdm nox -s mypy

# Test on current python version
$ pdm run test

# Test on all supported python versions
$ pdm run nox
```
