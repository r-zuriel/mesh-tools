#!/usr/bin/env bash
#
# mesh-send.sh — send a message from one agent identity to another via the file-bus.
#
# Usage:
#   mesh-send.sh <from> <to> <subject> [--priority normal|high|urgent] [--reply-to <msgid>]
#   The message body is read from stdin (free-form Markdown).
#
# Output: the path of the created file (lands in the recipient's inbox).
#
# Config (env):
#   MESH_BUS_DIR   (~/.claude/bus)   root of the file-bus

set -euo pipefail

BUS="${MESH_BUS_DIR:-$HOME/.claude/bus}"
PRIORITY="normal"
REPLY_TO=""

now_iso() { date +%Y-%m-%dT%H:%M:%S%z; }

if [ $# -lt 3 ]; then
  echo "Error: needs at least 3 args: <from> <to> <subject>" >&2
  echo "Usage: $0 <from> <to> <subject> [--priority high|urgent] [--reply-to <msgid>]" >&2
  exit 1
fi

FROM="$1"; shift
TO="$1"; shift
SUBJECT="$1"; shift

while [ $# -gt 0 ]; do
  case "$1" in
    --priority) PRIORITY="$2"; shift 2 ;;
    --reply-to) REPLY_TO="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Validate identities (filesystem-safe names)
for id in "$FROM" "$TO"; do
  if ! printf '%s' "$id" | grep -qE '^[a-z0-9_-]+$'; then
    echo "Error: invalid identity '$id' — use only [a-z0-9_-]" >&2
    exit 1
  fi
done

# Ensure recipient inbox exists
mkdir -p "$BUS/$TO/_read"

# Filename: timestamp + sender + random suffix (portable random; no xxd dependency)
TS=$(date +%Y%m%dT%H%M%S)
RAND=$(od -An -N4 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
[ -z "$RAND" ] && RAND=$(printf '%04x%04x' "$((RANDOM))" "$((RANDOM))")
MSGID="${TS}-from-${FROM}-${RAND}"
DEST="$BUS/$TO/${MSGID}.md"

# Read body from stdin
BODY=$(cat)
if [ -z "$BODY" ]; then
  echo "Error: empty message body (read from stdin)" >&2
  exit 1
fi

# Write atomically. Use an INTRA-directory temp file (not cross-filesystem) so
# file watchers (e.g. FSEvents/inotify) see the rename as a create event; a
# cross-fs mv from $TMPDIR would not generate a detectable event.
TMP="$BUS/$TO/.${MSGID}.tmp"
{
  echo "---"
  echo "from: $FROM"
  echo "to: $TO"
  echo "sent: $(now_iso)"
  echo "priority: $PRIORITY"
  if [ -n "$REPLY_TO" ]; then
    echo "in-reply-to: $REPLY_TO"
  fi
  echo "msg-id: $MSGID"
  echo "---"
  echo ""
  echo "# $SUBJECT"
  echo ""
  echo "$BODY"
} > "$TMP"
mv "$TMP" "$DEST"

# Update the identity registry (append if new)
REG="$BUS/_identities.md"
if [ ! -f "$REG" ]; then
  cat > "$REG" <<'EOF'
# Identities registered in the mesh

One line each: `- <id> · <description> · <last used>`

EOF
fi
for id in "$FROM" "$TO"; do
  if ! grep -qE "^- $id($| )" "$REG"; then
    echo "- $id · (no description) · first used $(now_iso)" >> "$REG"
  fi
done

echo "$DEST"
