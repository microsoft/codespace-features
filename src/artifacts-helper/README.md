
# Azure Artifacts Credential Helper (artifacts-helper)

Configures Codespace to authenticate with Azure Artifact feeds

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/artifacts-helper:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| nugetURIPrefixes | Nuget URI Prefixes | string | https://pkgs.dev.azure.com/ |
| dotnet6 | Use .NET 6 Runtime | boolean | false |
| dotnetAlias | Create alias for dotnet | boolean | true |
| nugetAlias | Create alias for nuget | boolean | true |

This installs [Azure Artifacts Credential Provider](https://github.com/microsoft/artifacts-credprovider)
and optionally configures an alias for `dotnet` and `nuget` that dynamically sets an authentication token
for pulling artifacts from a feed before running the command.

## OS Support

This feature is tested to work on Debian/Ubuntu and Mariner CBL 2.0


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/artifacts-helper/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
