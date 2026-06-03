#!/usr/bin/env bash
#
# mesh-check.sh — inspect an agent identity's inbox.
#
# Usage:
#   mesh-check.sh <my-identity>                 # list new messages
#   mesh-check.sh <my-identity> --show <msgid>  # print a full message
#   mesh-check.sh <my-identity> --read <msgid>  # mark a message read (move to _read/)
#   mesh-check.sh <my-identity> --all           # list everything (new + read)
#
# Config (env):
#   MESH_BUS_DIR   (~/.claude/bus)   root of the file-bus

set -euo pipefail

BUS="${MESH_BUS_DIR:-$HOME/.claude/bus}"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <my-identity> [--read <msgid> | --show <msgid> | --all]" >&2
  exit 1
fi

ME="$1"; shift

if ! printf '%s' "$ME" | grep -qE '^[a-z0-9_-]+$'; then
  echo "Error: invalid identity '$ME'" >&2
  exit 1
fi

INBOX="$BUS/$ME"
mkdir -p "$INBOX/_read"

# Default: list new messages
if [ $# -eq 0 ]; then
  count=0
  for f in "$INBOX"/*.md; do
    [ -e "$f" ] || continue
    count=$((count + 1))
    bn=$(basename "$f" .md)
    from_line=$(grep -m1 '^from:' "$f" 2>/dev/null | sed 's/^from: *//')
    prio=$(grep -m1 '^priority:' "$f" 2>/dev/null | sed 's/^priority: *//')
    sent=$(grep -m1 '^sent:' "$f" 2>/dev/null | sed 's/^sent: *//')
    subj=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# *//')
    prio_tag=""
    [ "$prio" = "urgent" ] && prio_tag=" [urgent]"
    [ "$prio" = "high" ] && prio_tag=" [high]"
    if [ "$count" -eq 1 ]; then
      echo "Inbox for '$ME' — new messages:"
      echo ""
    fi
    echo "  ${bn}${prio_tag}"
    echo "    from: $from_line · sent: $sent"
    echo "    subject: $subj"
    echo ""
  done
  if [ "$count" -eq 0 ]; then
    echo "Inbox for '$ME' is empty. No new messages."
    exit 0
  fi
  echo "Show full: $0 $ME --show <msgid>"
  echo "Mark read: $0 $ME --read <msgid>"
  exit 0
fi

CMD="$1"; shift
TARGET="${1:-}"

case "$CMD" in
  --show)
    [ -n "$TARGET" ] || { echo "Error: needs <msgid>" >&2; exit 1; }
    for path in "$INBOX/$TARGET.md" "$INBOX/_read/$TARGET.md"; do
      if [ -f "$path" ]; then
        cat "$path"
        exit 0
      fi
    done
    echo "Message not found: $TARGET" >&2
    exit 1
    ;;
  --read)
    [ -n "$TARGET" ] || { echo "Error: needs <msgid>" >&2; exit 1; }
    if [ -f "$INBOX/$TARGET.md" ]; then
      mv "$INBOX/$TARGET.md" "$INBOX/_read/"
      echo "Marked read: $TARGET"
      exit 0
    fi
    echo "Message not in inbox (already read?): $TARGET" >&2
    exit 1
    ;;
  --all)
    echo "Inbox '$ME' — all messages:"
    echo ""
    echo "[New]"
    for f in "$INBOX"/*.md; do
      [ -e "$f" ] || continue
      echo "  $(basename "$f" .md)"
    done
    echo ""
    echo "[Read]"
    for f in "$INBOX"/_read/*.md; do
      [ -e "$f" ] || continue
      echo "  $(basename "$f" .md)"
    done
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Valid: --show <msgid>, --read <msgid>, --all" >&2
    exit 1
    ;;
esac
