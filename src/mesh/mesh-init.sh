#!/usr/bin/env bash
#
# mesh-init.sh — initialize / inspect the file-bus and manage identities.
#
# Usage:
#   mesh-init.sh                          # show current state
#   mesh-init.sh register <id> [desc]     # register a new identity
#   mesh-init.sh set-default <id>         # set the default local identity
#   mesh-init.sh get-default              # print the resolved default identity
#
# Config (env):
#   MESH_BUS_DIR        (~/.claude/bus)                  root of the file-bus
#   MESH_IDENTITY_FILE  (~/.claude/.mesh-identity)       default-identity file
#   MESH_IDENTITY       (unset)                          overrides the file when set

set -euo pipefail

BUS="${MESH_BUS_DIR:-$HOME/.claude/bus}"
CURRENT_FILE="${MESH_IDENTITY_FILE:-$HOME/.claude/.mesh-identity}"
REG="$BUS/_identities.md"

now_iso() { date +%Y-%m-%dT%H:%M:%S%z; }

mkdir -p "$BUS"
if [ ! -f "$REG" ]; then
  cat > "$REG" <<'EOF'
# Identities registered in the mesh

One line each: `- <id> · <description> · <last used>`

EOF
fi

if [ $# -eq 0 ]; then
  echo "=== Mesh state ==="
  echo "Bus path: $BUS"
  echo ""
  echo "Registered identities:"
  grep -E '^- ' "$REG" || echo "  (none yet)"
  echo ""
  echo "Existing inboxes:"
  for d in "$BUS"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    new=$(find "$d" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
    read_count=$(find "$d/_read" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  $name → $new new, $read_count read"
  done
  exit 0
fi

CMD="$1"; shift

case "$CMD" in
  register)
    ID="${1:-}"; [ $# -gt 0 ] && shift
    DESC="${*:-(no description)}"
    [ -n "$ID" ] || { echo "Error: needs <id>" >&2; exit 1; }
    if ! printf '%s' "$ID" | grep -qE '^[a-z0-9_-]+$'; then
      echo "Error: invalid id — use only [a-z0-9_-]" >&2; exit 1
    fi
    if grep -qE "^- $ID( |$)" "$REG"; then
      echo "Identity '$ID' already registered"
      exit 0
    fi
    echo "- $ID · $DESC · registered $(now_iso)" >> "$REG"
    mkdir -p "$BUS/$ID/_read"
    echo "Identity '$ID' registered. Inbox: $BUS/$ID/"
    ;;
  set-default)
    ID="${1:-}"
    [ -n "$ID" ] || { echo "Error: needs <id>" >&2; exit 1; }
    if ! printf '%s' "$ID" | grep -qE '^[a-z0-9_-]+$'; then
      echo "Error: invalid id" >&2; exit 1
    fi
    echo "$ID" > "$CURRENT_FILE"
    echo "Default identity set: $ID"
    echo "(Resolution order: \$MESH_IDENTITY env > $CURRENT_FILE > anon-\$PID)"
    ;;
  get-default)
    if [ -n "${MESH_IDENTITY:-}" ]; then
      echo "$MESH_IDENTITY (from env)"
    elif [ -f "$CURRENT_FILE" ]; then
      echo "$(cat "$CURRENT_FILE") (from $CURRENT_FILE)"
    else
      echo "anon-\$PID (no default; use 'mesh-init.sh set-default <id>')"
    fi
    ;;
  *)
    echo "Unknown command: $CMD (valid: register, set-default, get-default)" >&2
    exit 1
    ;;
esac
