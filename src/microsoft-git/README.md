
# Microsoft Git for monorepo with GVFS support (microsoft-git)

A fork of Git containing Microsoft-specific patches

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/microsoft-git:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of Microsoft Git, if not latest. | string | latest |


This installs the [Microsoft fork of Git](https://github.com/microsoft/git) that includes
Scalar and support for GVFS protocol.

## OS Support

This feature is tested on base images for Debian/Ubuntu and Mariner-CBL 2.0

On Debian/Ubuntu, the installer supports current
`microsoft-git_<version>_linux_<architecture>.deb` release assets and older
`microsoft-git_<version>_<architecture>.deb` assets. Legacy
`microsoft-git_<version>.deb` assets are supported on amd64 only; they are not
architecture-independent packages.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/microsoft-git/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
