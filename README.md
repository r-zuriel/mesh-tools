# mesh-tools

**Visibility & methodology tools for AI-augmented infrastructure work.**

A toolkit for developers and SREs who run [Claude Code](https://docs.claude.com/en/docs/claude-code) on real infrastructure and want better session visibility, structured inter-agent communication, and repeatable working methods.

> Status: `0.x` — experimental. APIs and file layouts may change between minor versions. Use at your own risk.

## Why

Long agent sessions lose clarity. Multiple specialized agents need a way to talk. Operational work benefits from named, repeatable methods instead of ad-hoc decisions. `mesh-tools` packages three things that address this:

- **Visibility** — session black-box logging, periodic checkpoints, and subagent telemetry, so you can see what an agent actually did.
- **Mesh** — a file-based message bus so independent agent identities can hand off work to each other.
- **Methodology** — sanitized, reusable templates for destructive-op safety, staged rollouts, peer review, and post-work documentation.

## Components & roadmap

| Version | Component | What it adds |
|---|---|---|
| `v0.1.0` | Visibility hooks | `session-logger`, `dw-monitor` — black-box logs + subagent telemetry |
| `v0.2.0` | Mesh file-bus | `mesh-send` / `mesh-check` / `mesh-init` + identity templates |
| `v0.3.0` | Methodology templates | destructive-op checks, staged rollout, peer review, doc-on-close |
| `v0.4.0` | Semantic distillation | `session-distiller` — compress closed sessions into concise lessons |
| `v1.0.0` | Docs + launch | architecture guide, examples, stable layout |

Nothing is published yet — this is the scaffold (F1). See [CHANGELOG.md](CHANGELOG.md).

## Install

Requires Node.js ≥ 18 and Claude Code.

```bash
npx @r-zuriel/mesh-tools init
```

Full setup in [docs/INSTALL.md](docs/INSTALL.md).

## Quickstart

```bash
# Inspect available commands
npx @r-zuriel/mesh-tools --help

# Scaffold the hooks + bus into your ~/.claude (interactive, non-destructive)
npx @r-zuriel/mesh-tools init
```

## Architecture

The tools assume a layered model: a base CLI/agent, visibility on top, then a mesh of specialized identities, then methodology applied across them. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Ricardo Zuriel Nuño Vazquez

---

Built by Ricardo Zuriel Nuño Vazquez — Infrastructure & Observability Engineer · Available for freelance.
