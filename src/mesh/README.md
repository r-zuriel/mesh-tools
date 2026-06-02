# Mesh file-bus

Async, file-based message passing between agent identities. Ships in **v0.2.0**.

Planned contents:

- `mesh-init.sh` — initialize the bus directory structure.
- `mesh-send.sh` — send a message to another identity's inbox.
- `mesh-check.sh` — read, show, and mark-read messages in an inbox.
- Identity templates (`*-template.md`) — generic reviewer / documenter /
  methodologist / dev roles, with matching skill activators.

Messages live under `~/.claude/bus/<identity>/<msgid>.md`. Placeholder directory
in the current scaffold.
