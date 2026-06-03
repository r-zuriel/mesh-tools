# Mesh file-bus

Async, file-based message passing between agent identities. No daemon, no broker —
just files under a bus directory, so it works anywhere a filesystem does and is
trivial to inspect, version, or back up.

Each message is a Markdown file with a YAML frontmatter header, written to the
recipient's inbox:

```
$MESH_BUS_DIR/<identity>/<msgid>.md           # new
$MESH_BUS_DIR/<identity>/_read/<msgid>.md      # after --read
```

Requires `bash` and standard POSIX tools. `MESH_BUS_DIR` defaults to
`~/.claude/bus`.

## Scripts

### `mesh-send.sh`
```bash
mesh-send.sh <from> <to> <subject> [--priority normal|high|urgent] [--reply-to <msgid>]
# body is read from stdin
echo "the body" | mesh-send.sh dev reviewer "Code review: my-repo" --priority high
```
Writes the message atomically (intra-directory temp + `mv`, so file watchers see a
create event) and registers new identities in `_identities.md`.

### `mesh-check.sh`
```bash
mesh-check.sh <me>                 # list new messages
mesh-check.sh <me> --show <msgid>  # print a full message
mesh-check.sh <me> --read <msgid>  # move to _read/
mesh-check.sh <me> --all           # list new + read
```

### `mesh-init.sh`
```bash
mesh-init.sh                       # show bus state + identities
mesh-init.sh register <id> [desc]  # register an identity + create its inbox
mesh-init.sh set-default <id>      # set the local default identity
mesh-init.sh get-default           # resolve default: $MESH_IDENTITY > file > anon
```

## Identity templates

Generic starting points under [`identities/`](identities/) — copy, rename, and
adapt to your own roles. They are templates, not personas:

- [`dev-template.md`](identities/dev-template.md) — builder
- [`reviewer-template.md`](identities/reviewer-template.md) — adversarial reviewer
- [`documenter-template.md`](identities/documenter-template.md) — knowledge-base curator
- [`methodologist-template.md`](identities/methodologist-template.md) — method designer

A typical handoff: a `dev` identity sends a pre-release review request to a
`reviewer`, which replies with a verdict (`--reply-to`), and a `documenter` audits
the result when the phase closes.

## Config

| Env | Default | Purpose |
|---|---|---|
| `MESH_BUS_DIR` | `~/.claude/bus` | root of the file-bus |
| `MESH_IDENTITY_FILE` | `~/.claude/.mesh-identity` | default-identity file |
| `MESH_IDENTITY` | _(unset)_ | overrides the file when set |
