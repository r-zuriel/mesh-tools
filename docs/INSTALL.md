# Installation

`mesh-tools` targets [Claude Code](https://docs.claude.com/en/docs/claude-code)
on macOS or Linux. It requires Node.js ≥ 18 and a POSIX `bash`.

## Prerequisites

- Node.js ≥ 18 (`node --version`)
- Claude Code installed and configured
- `bash`, `jq` (used by mesh and distiller components in later versions)

## Run without installing

```bash
npx @r-zuriel/mesh-tools init
```

## Install globally

```bash
npm install -g @r-zuriel/mesh-tools
mesh-tools --help
```

## What `init` does

`init` is interactive and non-destructive: it scaffolds the visibility hooks
and the mesh bus into your `~/.claude` directory, backing up any file it would
otherwise overwrite. It never disables Claude Code's native memory or removes
existing hooks.

> In the current scaffold (`0.0.0`) `init` is a stub. Component installers ship
> starting in `v0.1.0`.

## Uninstall

Global install:

```bash
npm uninstall -g @r-zuriel/mesh-tools
```

Scaffolded hooks and bus files under `~/.claude` are listed by `init` and can be
removed manually; a future `mesh-tools clean` will automate this.
