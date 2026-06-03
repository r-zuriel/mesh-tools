# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] — Methodology templates

### Added
- Seven methodology docs under `src/methods/` (Cordada, staged mass rollout,
  pre-flight/flags/gotchas, peer-review severity classifier, the 4 checks, mesh
  peer-review, document-on-close), each with when-to-use / steps / when-NOT /
  example.
- Four copy-paste templates under `src/methods/templates/` (mass-change work-log,
  technical ADR, business ADR, build & frontend gotchas).
- Index in `src/methods/README.md`.

### Notes
- All methods are harvested from real operations and anonymized for public use.

## [0.2.0] — Mesh file-bus

### Added
- `src/mesh/mesh-send.sh` — send a Markdown message to another identity's inbox,
  with priority and `--reply-to` threading; atomic write via intra-directory temp.
- `src/mesh/mesh-check.sh` — list / show / mark-read inbox messages.
- `src/mesh/mesh-init.sh` — initialize the bus, register identities, manage the
  default local identity.
- Four generic identity templates under `src/mesh/identities/` (dev, reviewer,
  documenter, methodologist).
- Mesh round-trip smoke tests (`test/mesh.test.sh`), wired into `npm test`.
- Configurable via `MESH_BUS_DIR`, `MESH_IDENTITY_FILE`, `MESH_IDENTITY`.
- `SECURITY.md` — trust model and `MESH_BUS_DIR` guidance.

### Notes
- Portable: no `xxd` dependency (uses `od` with a `$RANDOM` fallback) and no
  `date -Iseconds`.

## [0.1.0] — Session visibility

### Added
- `src/hooks/session-logger.sh` — PostToolUse hook: per-session black-box log of
  Bash/Write/Edit actions plus a checkpoint reminder injected every N actions.
  Configurable via `MESH_CHECKPOINT_EVERY` and `MESH_SESSION_LOG_DIR`.
- `src/hooks/dw-monitor.sh` — PostToolUse hook: Task/Agent subagent telemetry,
  cumulative `_metrics.json`, and a high-failure-rate alert. Configurable via
  `MESH_DW_LOG_DIR`, `MESH_DW_ALERT_PCT`, `MESH_DW_ALERT_MIN`.
- `src/hooks/README.md` — usage and `settings.json` install snippet.
- Hook smoke tests (`test/hooks.test.sh`), wired into `npm test`.

### Notes
- Hooks are portable across macOS/Linux: no `bc` dependency (integer math) and
  no `date -Iseconds` (BSD `date` lacks it).

## [0.0.0] — Scaffold

### Added
- Project scaffold (F1): repository structure, MIT license, `package.json`,
  CLI entrypoint skeleton, CI workflow, base documentation.
- CI secret scanning via gitleaks on every push and pull request.

[Unreleased]: https://github.com/r-zuriel/mesh-tools/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/r-zuriel/mesh-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/r-zuriel/mesh-tools/releases/tag/v0.1.0
