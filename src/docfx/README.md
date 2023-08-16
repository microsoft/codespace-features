
# DocFX (docfx)

Installs docfx tools

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/docfx:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select version of DocFX | string | 2.67.5 |

## Customizations

### VS Code Extensions

- `yzhang.markdown-all-in-one`

This feature installs the latest version compatible with Microsoft's internal documentation
platform which is currently 2.67.5. You can install a different version or 'latest" by using
the 'version' option.

## OS Support

This feature requires `dotnet tool` and will attempt to install .NET 6.0. It is tested to work on Debian/Ubuntu and Mariner CBL 2.0


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/docfx/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
