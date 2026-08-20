# mesh-tools

[![CI](https://github.com/r-zuriel/mesh-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/r-zuriel/mesh-tools/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/r-zuriel/mesh-tools)](https://github.com/r-zuriel/mesh-tools/releases)
**License:** source-available, all rights reserved — see [LICENSE](LICENSE)

**Visibility & methodology tools for AI-augmented infrastructure work.**

A toolkit for developers and SREs who run [Claude Code](https://docs.claude.com/en/docs/claude-code) on real infrastructure and want better session visibility, structured inter-agent communication, and repeatable working methods.

## Why

Long agent sessions lose clarity. Multiple specialized agents need a way to talk. Operational work benefits from named, repeatable methods instead of ad-hoc decisions. `mesh-tools` packages four things that address this:

- **Visibility** — session black-box logging, periodic checkpoints, and subagent telemetry, so you can see what an agent actually did.
- **Mesh** — a file-based message bus so independent agent identities can hand off work to each other.
- **Methodology** — sanitized, reusable methods and templates for destructive-op safety, staged rollouts, peer review, and post-work documentation.
- **Distillation** — compress each closed session into a handful of concrete lessons you actually revisit.

Everything is plain `bash` + `jq` over the local filesystem. No daemon, no database, no required network — only the optional distiller calls a model, through your own `claude` CLI.

## Components

| Component | What it does | Docs |
|---|---|---|
| `session-logger` | Black-box log of every Bash/Write/Edit + periodic checkpoint reminders | [src/hooks/README.md](src/hooks/README.md) |
| `dw-monitor` | Subagent (Task/Agent) telemetry with failure-rate alerts | [src/hooks/README.md](src/hooks/README.md) |
| `session-distiller` | On session close, distill the log into 3-5 operational lessons | [src/hooks/README.md](src/hooks/README.md) |
| `mesh-send` / `mesh-check` / `mesh-init` | Async message bus between agent identities, with 4 generic identity templates | [src/mesh/README.md](src/mesh/README.md) |
| Methods & templates | 7 methods + 4 copy-paste templates harvested from real operations | [src/methods/README.md](src/methods/README.md) |

## Install

Requires Claude Code, `bash`, and [`jq`](https://jqlang.github.io/jq/) on macOS or Linux.

```bash
git clone https://github.com/r-zuriel/mesh-tools.git
cd mesh-tools
npm test   # optional sanity check (needs Node.js ≥ 18)
```

Then wire the components you want — each is independent:

1. **Visibility hooks**: copy `src/hooks/*.sh` somewhere stable and reference them from `.claude/settings.json` ([wiring guide](src/hooks/README.md#install)).
2. **Mesh bus**: put `src/mesh/*.sh` on your `PATH` and run `mesh-init.sh init` ([guide](src/mesh/README.md)).
3. **Methods**: read them; copy the templates into your workflow ([index](src/methods/README.md)).

Full walkthrough in [docs/INSTALL.md](docs/INSTALL.md). An `npx` installer is planned; today the wiring is manual and documented.

## Quickstart: see your sessions

```jsonc
// .claude/settings.json — minimal visibility setup
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Bash|Write|Edit",
        "hooks": [{ "type": "command", "command": "/path/to/session-logger.sh", "timeout": 5 }] }
    ]
  }
}
```

Every session now writes `~/.claude/session-logs/YYYYMMDD-<id>.md` and reminds the agent to summarize progress every 15 actions. Add the [distiller](src/hooks/README.md#session-distillersh) and each closed session also leaves 3-5 distilled lessons behind.

## Quickstart: two identities talking

```bash
mesh-init.sh init
mesh-init.sh register builder
mesh-init.sh register reviewer

echo "Plan attached — pre-release review please." | \
  mesh-send.sh builder reviewer "Review request: my-app v1.2.0"

mesh-check.sh reviewer            # list inbox
mesh-check.sh reviewer --show <msgid>
```

Identity templates (dev, reviewer, documenter, methodologist) live in [src/mesh/identities/](src/mesh/identities/).

## Architecture

The tools assume a layered model: a base CLI/agent, visibility on top, then a mesh of specialized identities, then methodology applied across them. Each layer is useful alone; they compound when combined. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

### The file-bus mesh

The mesh is deliberately boring: no daemon, no broker, no network. A message is a
Markdown file with a YAML frontmatter header, written into the recipient's inbox
directory. `mesh-send` writes it atomically (an intra-directory temp file renamed
into place) so an external file watcher — FSEvents on macOS, inotify on Linux —
sees a single, clean create event and can wake the recipient. Nothing here polls;
the filesystem is the queue.

```mermaid
flowchart LR
    dev["dev<br/>(sender identity)"]
    rev["reviewer<br/>(recipient identity)"]

    subgraph BUS["MESH_BUS_DIR  (~/.claude/bus)"]
        inbox["reviewer/&lt;msgid&gt;.md<br/>new"]
        read["reviewer/_read/&lt;msgid&gt;.md<br/>after --read"]
        reg["_identities.md<br/>registry"]
    end

    dev -- "mesh-send.sh<br/>atomic temp + mv" --> inbox
    inbox -. "create event<br/>(FSEvents / inotify)" .-> rev
    rev -- "mesh-check.sh --show" --> inbox
    rev -- "mesh-check.sh --read" --> read
    dev -. "auto-register" .-> reg
    rev -. "auto-register" .-> reg
```

Every message file carries `from`, `to`, `sent`, `priority`, `msg-id`, and an
optional `in-reply-to` in its frontmatter — so a thread is reconstructable from
the files alone, and the whole bus is trivial to inspect, `grep`, version, or back
up. The trust boundary is the local user (see [SECURITY.md](SECURITY.md)); keep
`MESH_BUS_DIR` under `$HOME`.

## What's in the box

```
mesh-tools/
├── bin/        mesh-tools CLI — --help/--version + init (points at the wiring guides)
├── src/
│   ├── hooks/  session-logger · dw-monitor · session-distiller (visibility)
│   ├── mesh/   mesh-send · mesh-check · mesh-init + 4 identity templates
│   └── methods/ 7 methods + 4 copy-paste templates (methodology)
├── examples/   settings.json wiring + an end-to-end mesh handoff walkthrough
├── docs/       ARCHITECTURE.md · INSTALL.md
└── test/       bash test suite (npm test)
```

No runtime dependencies: everything is `bash` + `jq` + standard POSIX tools, with a
thin Node entrypoint for the CLI.

## Security

See [SECURITY.md](SECURITY.md) for the trust model — in short: local filesystem, same-user trust boundary, keep `MESH_BUS_DIR` under `$HOME`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and war stories from your own deployments are welcome.

## License

All rights reserved © 2026 Ricardo Zuriel Nuño Vázquez — see [LICENSE](LICENSE)

---

Built by Ricardo Zuriel Nuno Vazquez — Infrastructure & Observability Engineer · Available for freelance.
