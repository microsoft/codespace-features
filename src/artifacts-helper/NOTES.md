This installs [Azure Artifacts Credential Provider](https://github.com/microsoft/artifacts-credprovider)
and optionally configures an alias for `dotnet`, `nuget`, `npm`, `yarn`, and `rush` that dynamically sets an authentication token
for pulling artifacts from a feed before running the command.

For `npm`, `yarn`, and `rush` this requires that your `~/.npmrc` file is configured to use the ${ARTIFACTS_ACCESSTOKEN}
environment variable for the `authToken`. A helper script has been added that you can use to write your `~/.npmrc`
file during your setup process, though there are many ways you could accomplish this. To use the script, run it like
this:

```
write-npm.sh pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm
write-npm.sh pkgs.dev.azure.com/orgname/projectname/_packaging/feed2/npm username
write-npm.sh pkgs.dev.azure.com/orgname/projectname/_packaging/feed3/npm username email
```

You must pass the feed name to the script, but you can optionally provide a username and email if desired. Defaults
are put in place if they are not provided. An example of the `.npmrc` file created is this:

```
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/registry/:username=codespaces
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/registry/:_authToken=${ARTIFACTS_ACCESSTOKEN}
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/registry/:email=codespaces@github.com
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/:username=codespaces
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/:_authToken=${ARTIFACTS_ACCESSTOKEN}
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/:email=codespaces@github.com
```

## OS Support

This feature is tested to work on Debian/Ubuntu and Mariner CBL 2.0
