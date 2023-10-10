
# DevTool (devtool)

Install DevTool

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/devtool:1": {}
}
```



## Customizations

### VS Code Extensions

- `ms-codespaces-tools.ado-codespaces-auth`

This installs a Microsoft-internal tool named DevTool. This will also install
the `xdg-utils` package so that the `xdg-open` CLI is available for the
DevTool CLI to be able to use to open a web browser.

## OS Support

This feature is tested to work on Debian/Ubuntu


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/devtool/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
