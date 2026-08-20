# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **License changed from MIT to source-available / All Rights Reserved** (portfolio policy).
  Note: the MIT grant on previously released versions (v1.0.0 and earlier) remains in effect
  for those versions and is not retroactively revocable; the new terms apply going forward.

## [1.0.0] — Stable layout

First stable release. No new components — this consolidates v0.1.0-v0.4.0
into a coherent, documented whole.

### Changed
- README rewritten for visitors: component table with per-component docs,
  honest install path (git clone + manual wiring; `npx` installer is planned,
  not promised), real quickstarts for visibility and mesh.
- `docs/INSTALL.md` rewritten around the actual manual setup, with full
  uninstall steps.
- `docs/ARCHITECTURE.md` now covers the distiller in the visibility layer.
- `mesh-tools init` stub now points to the per-component wiring guides instead
  of a stale roadmap note.

### Stability
- File layouts (`src/hooks`, `src/mesh`, `src/methods`), env var names
  (`MESH_*`), and the bus message format are now considered stable; breaking
  changes bump the major version.

## [0.4.0] — Semantic distillation

### Added
- `src/hooks/session-distiller.sh` — on `SessionEnd`, compresses the session's
  black-box log (written by `session-logger.sh`) into 3-5 concrete operational
  lessons via `claude --print` and appends them to a monthly
  `auto-distilled-YYYYMM.md`. Never touches Claude Code's native memory or
  `MEMORY.md`; always exits 0.
- Distiller tests (`test/distiller.test.sh`, T1-T6 incl. timeout and append
  race), wired into `npm test` with a fake `claude` on PATH — no tokens spent.
- Distiller section in `src/hooks/README.md` (env vars, `SessionEnd` wiring,
  recursion sentinel).

### Notes
- Portable: background-watchdog timeout (macOS has no coreutils `timeout`) and
  atomic-`mkdir` locking (no `flock`).
- Use `SessionEnd`, not `Stop` (`Stop` fires per turn and would duplicate), and
  `claude --print` without `--bare` (`--bare` skips credential loading and
  breaks auth).

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

[Unreleased]: https://github.com/r-zuriel/mesh-tools/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/r-zuriel/mesh-tools/compare/v0.4.0...v1.0.0
[0.4.0]: https://github.com/r-zuriel/mesh-tools/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/r-zuriel/mesh-tools/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/r-zuriel/mesh-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/r-zuriel/mesh-tools/releases/tag/v0.1.0
