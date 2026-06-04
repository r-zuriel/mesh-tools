# Installation

`mesh-tools` targets [Claude Code](https://docs.claude.com/en/docs/claude-code)
on macOS or Linux.

## Prerequisites

- Claude Code installed and configured
- `bash` and [`jq`](https://jqlang.github.io/jq/)
- Node.js ≥ 18 — only needed to run the test suite and the CLI stub
- For the distiller: the `claude` CLI authenticated on the machine

## Get the code

```bash
git clone https://github.com/r-zuriel/mesh-tools.git
cd mesh-tools
npm test   # optional: 29 smoke/unit tests, no tokens spent
```

Components are independent — wire only what you want. Setup is manual today
(an `npx` installer is planned); every step below is copy-paste.

## 1. Visibility hooks

```bash
mkdir -p ~/.claude/scripts
cp src/hooks/session-logger.sh src/hooks/dw-monitor.sh src/hooks/session-distiller.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/{session-logger,dw-monitor,session-distiller}.sh
```

Then reference them from `~/.claude/settings.json` — exact JSON in
[src/hooks/README.md § Install](../src/hooks/README.md#install). **Back up your
`settings.json` before editing it.**

- `session-logger.sh` + `dw-monitor.sh` → `PostToolUse`
- `session-distiller.sh` → `SessionEnd` (NOT `Stop` — it fires per turn)

## 2. Mesh bus

```bash
cp src/mesh/mesh-send.sh src/mesh/mesh-check.sh src/mesh/mesh-init.sh ~/.local/bin/   # or anywhere on PATH
chmod +x ~/.local/bin/mesh-{send,check,init}.sh
mesh-init.sh init
mesh-init.sh register <your-first-identity>
```

> Note: `~/.local/bin` is **not** on `PATH` by default on stock macOS — add
> `export PATH="$HOME/.local/bin:$PATH"` to your shell profile, or copy the
> scripts to a directory already on your `PATH`.

Identity templates to adapt are in [src/mesh/identities/](../src/mesh/identities/).
Trust model and `MESH_BUS_DIR` guidance: [SECURITY.md](../SECURITY.md).

## 3. Methods & templates

Nothing to install — read [src/methods/README.md](../src/methods/README.md) and
copy the templates you use into your own workflow.

## Uninstall

Everything lives in plain files you copied:

- remove the scripts you placed in `~/.claude/scripts/` / your `PATH`
- remove their entries from `~/.claude/settings.json`
- the bus directory (default `~/.claude/bus/`) and logs
  (`~/.claude/session-logs/`, `~/.claude/dw-logs/`, `~/.claude/distilled/`) are
  yours to keep or delete

Nothing else is modified: the toolkit never disables Claude Code's native
memory or removes hooks it didn't add.
