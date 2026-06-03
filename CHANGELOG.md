# Changelog

All notable changes to this project are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/r-zuriel/mesh-tools/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/r-zuriel/mesh-tools/releases/tag/v0.1.0
