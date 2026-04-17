# Installation

`dev.kit` supports two install paths:

- `npm install -g @udx/dev-kit`
- `curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/latest/bin/scripts/install.sh | bash`

Whichever path you use last becomes the active install. The installer cleans up the other path first so one install owns `dev.kit` at a time.

Installation only puts the command on the machine. The normal operating loop starts after install:

```bash
dev.kit
dev.kit repo
dev.kit agent
```

That loop refreshes repo context, regenerates `AGENTS.md`, and makes the next work step explicit before an agent or developer starts changing the repo.

## Recommended Path

Use npm when it is available:

```bash
npm install -g @udx/dev-kit
```

This is the default path.

## Curl Install

Use curl when npm is not available or not desired:

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/latest/bin/scripts/install.sh | bash
```

The curl installer creates:

- `~/.udx/dev.kit` as the install home
- `~/.local/bin/dev.kit` as the executable shim

It does not edit shell profile files. If `~/.local/bin` is not already in `PATH`, the installer tells you what to export manually.

## Smart Cleanup

Install cleanup is symmetric:

- npm install removes a prior curl-managed install from `~/.udx/dev.kit` and `~/.local/bin/dev.kit`
- curl install removes a prior global npm package install of `@udx/dev-kit`

This keeps users from ending up with conflicting binaries or stale install homes.

## npm Install

The npm package runs a postinstall hook. That hook checks for the curl-managed home and shim. If they exist and the shim points at the curl install, it removes them and leaves the npm install as the only active one.

## Curl Install Behavior

The curl installer checks whether `@udx/dev-kit` is already installed globally through npm. If it is, the installer removes that package first and then lays down the curl-managed home and shim.

The installer also supports both execution styles:

- `bash install.sh`
- `bash < install.sh`

That matters because the public curl flow pipes the script into `bash`.

## Uninstall

The curl-managed install can be removed with:

```bash
dev.kit uninstall
```

Or non-interactively:

```bash
dev.kit uninstall --yes
```

This removes:

- `~/.local/bin/dev.kit`
- `~/.udx/dev.kit`

It does not modify shell profile files.

For npm-managed installs, remove the package with:

```bash
npm uninstall -g @udx/dev-kit
```

## Verify

After either install path, verify the active install with:

```bash
dev.kit
```

That confirms the command resolves correctly and shows the next step in the session flow.

After that, continue with:

```bash
dev.kit repo
dev.kit agent
```

The goal is not only to confirm that the binary works. The goal is to start the session from current repo contract and current GitHub-aware workflow guidance rather than stale local memory.
