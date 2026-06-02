# Architecture

`mesh-tools` is organized around a layered model of AI-augmented infrastructure
work. Each layer is only sustainable once the one below it is in place.

```
┌─────────────────────────────────────────────┐
│  Methodology   reusable methods & templates  │  src/methods
├─────────────────────────────────────────────┤
│  Mesh          inter-identity message bus    │  src/mesh
├─────────────────────────────────────────────┤
│  Visibility    logs · checkpoints · telemetry│  src/hooks
├─────────────────────────────────────────────┤
│  Base          Claude Code + your shell      │  (provided)
└─────────────────────────────────────────────┘
```

## Layers

### Visibility (`src/hooks`)
Hooks that record what an agent does and surface it back. A session logger
writes a black-box log of every Bash/Write/Edit and injects periodic
checkpoints; a subagent monitor records Task/Agent invocations and aggregates
failure rates.

### Mesh (`src/mesh`)
A file-based message bus. Independent agent identities exchange async messages
under a per-identity inbox directory, enabling handoffs (e.g. a builder asking a
reviewer for a pre-release check).

### Methodology (`src/methods`)
Sanitized, copy-paste templates that encode safe operating procedures:
destructive-op checks, staged rollouts, peer review, and documentation on close.
Each ships with explicit "when to use" and "when NOT to use" guidance.

## Design principles

- **Non-destructive by default.** Installers back up before overwriting and
  never disable native Claude Code behavior.
- **No private data.** The toolkit is generic; it ships no org-specific
  identities, hostnames, or operational records.
- **No required network.** Visibility and mesh work entirely on the local
  filesystem. Only optional semantic distillation calls an API.
- **Composable.** Each layer is useful alone; they compound when combined.
