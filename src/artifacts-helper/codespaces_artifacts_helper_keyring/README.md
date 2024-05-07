# codespaces_artifacts_helper_keyring

The `codespaces_artifacts_helper_keyring` package provides [keyring](https://pypi.org/project/keyring) authentication for consuming Python packages from Azure Artifacts feeds using the [Codespaces Artifacts Helper](https://github.com/microsoft/codespace-features/tree/main/src/artifacts-helper) and its underlying authentication tool, [ado-codespaces-auth](https://github.com/microsoft/ado-codespaces-auth).

This package is an extension to [keyring](https://pypi.org/project/keyring), which will automatically find and use it once installed. Both [pip](https://pypi.org/project/pip) and [twine](https://pypi.org/project/twine) will use keyring to find credentials.

## Installation

### From Source

To install this package from source:

```sh
$ cd src/artifacts-helper/codespaces_artifacts_helper_keyring

# PDM is used to manage the project
$ pip install 'pdm>=2.14'

# Install dependencies and build the package
$ pdm build

# Install package and dependencies with pip
$ pip install dist/codespaces_artifacts_helper_keyring-*.whl
```

### From GitHub Releases

TODO: Write instructions

## Usage

### Requirements

To use `codespaces_artifacts_helper_keyring` to set up authentication between `pip` and Azure Artifacts, the following requirements must be met:

- pip version **19.2** or higher
- python version **3.8** or higher
- running inside a Codespace with [Codespaces Artifacts Helper](https://github.com/microsoft/codespace-features/tree/main/src/artifacts-helper) and the `param` option set to `true`. This will automatically install the `codespaces_artifacts_helper_keyring` package for you.
  ```json
  {
    "features": {
      "ghcr.io/microsoft/codespace-features/artifacts-helper:1": {
        "python": true
      }
    }
  }
  ```

### Inner Workings

The `codespaces_artifacts_helper_keyring` will detect if the package index has a domain that matches Azure Artifacts, e.g. `pkgs.dev.azure.com`. If it does, it will use the `ado-codespaces-auth` tool at `~/ado-auth-helper` to fetch an access token. This token will be used to authenticate with the Azure Artifacts feed.

### Installing Packages from an Azure Artifacts Feed

Once the codespace is ready, to consume a package, use the following `pip` command, replacing **<org_name>** and **<feed_name>** with your own, and **<package_name>** with the package you want to install:

```
pip install <package_name> --index-url https://pkgs.dev.azure.com/<org_name>/_packaging/<feed_name>/pypi/simple
```

## Contributing

We use [PDM](https://pdm-project.org/) to manage the project and its dependencies. To get started, install PDM:

```sh
$ pip install 'pdm>=2.14'
```

Then, install the project dependencies:

```sh
$ pdm install
```

### Scripts

A set of scripts are in `pyproject.toml` to help with common tasks. These can be run using `pdm <script name> <extra args>`. For example:

```sh
# Lint and exit with non-zero status if there are issues
$ pdm lint

# Lint and attempt to fix issues
$ pdm run lint-fix

# Format and fix issues
$ pdm run format [target files or directories]

# Type check
$ pdm mypy

# Run tests
$ pdm tests

# Test on all supported Python versions
$ pdm run nox
```

The scripts are wrappers around [nox](https://github.com/wntrblm/nox) sessions. You can directly run them from nox and use more specific filters. For example, to list the sessions that would run tests on Python 3.11:

```sh
$ pdm run nox -l -s tests --python '3.11'

* tests(python='3.11', keyring='20') -> Run the test suite.
* tests(python='3.11', keyring='25.1') -> Run the test suite.
```

The underlying [nox](https://github.com/wntrblm/nox) configuration is defined in `noxfile.py`. You can modify this file to add new test environments or change the behavior of existing ones. Any tests with the `"ci"` tag will be run in the CI pipeline.
