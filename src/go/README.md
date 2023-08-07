
# Go (go)

Installs Go and common Go utilities. Auto-detects latest version and installs needed dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/go:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Go version to install | string | latest |
| golangciLintVersion | Version of golangci-lint to install | string | latest |

## Customizations

### VS Code Extensions

- `golang.Go`



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed
as well as Azure Linux (Mariner) with the `tdnf` package manager installed.

`bash` is required to execute the `install.sh` script.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/go/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
