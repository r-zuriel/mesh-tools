# Contributing

This is an experimental personal toolkit released in the open. Contributions,
issues, and suggestions are welcome, but support is best-effort.

## Ground rules

- **Shell**: POSIX-friendly `bash`. Lint with `shellcheck` before opening a PR.
- **Node**: the CLI targets Node ≥ 18, no runtime dependencies where avoidable.
- **Docs**: every component ships a "how to use" and a "when NOT to use" section.
- **No secrets**: never commit credentials, tokens, real hostnames, IPs, or
  internal domains. CI and review will reject anything that looks private.

## Workflow

1. Open an issue describing the change.
2. Branch from `main`.
3. Keep commits focused; run `npm run lint` and `npm test` locally.
4. Open a PR — CI runs lint + smoke tests.

## Scope

`mesh-tools` packages generic, reusable tooling. It deliberately ships no
organization-specific configuration, identities, or operational data.
