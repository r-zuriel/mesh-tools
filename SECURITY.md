# Security

`mesh-tools` is local-first tooling: it reads and writes files under directories
you configure. There is no network listener and no privileged component. The
notes below describe the trust assumptions and how to stay within them.

## `MESH_BUS_DIR` must be a user-owned directory

The mesh scripts write messages and an identity registry under `MESH_BUS_DIR`
(default `~/.claude/bus`). Identity **names** are validated (`[a-z0-9_-]`), but
the **bus path itself is whatever you set it to**.

Keep `MESH_BUS_DIR` under a directory you own — `$HOME` or a user-owned
`$TMPDIR`. Do **not** point it at system locations such as `/etc`, `/var`,
`/usr`, or any shared/world-writable path:

- A shared bus path lets other users read your messages (they are plain files).
- A system path invites confusion with real configuration and may write
  unexpected `*.md` files into sensitive directories.

The hooks behave the same way: `MESH_SESSION_LOG_DIR` and `MESH_DW_LOG_DIR`
should also stay under a directory you own.

## Messages are not encrypted

Bus messages are plain Markdown on the local filesystem. Anyone who can read the
bus directory can read the messages. Do not put secrets (tokens, passwords,
keys) in message bodies.

## No code execution from messages

Messages are data. The scripts never evaluate message contents as code. The
hooks only ever emit `additionalContext` strings; they do not run anything from
a session log.

## Reporting

This is an experimental personal toolkit. To report a security concern, open an
issue describing the impact and reproduction. There is no formal SLA.
