#!/usr/bin/env bash
#
# session-distiller.sh — semantic distillation of closed Claude Code sessions.
#
# Reads a session black-box log (written by session-logger.sh), compresses it
# with Claude into 3-5 concrete operational lessons, and appends the result to a
# monthly distillation file. Designed to run from a Claude Code `SessionEnd`
# hook (NOT `Stop` — Stop fires once per turn and would re-distill the same log
# on every response).
#
# It NEVER fails the hook (always exits 0) and NEVER touches Claude Code's
# native memory or MEMORY.md — it only appends to auto-distilled-YYYYMM.md.
#
# Input  : JSON on stdin, e.g. {"session_id":"<uuid>", ...}
# Output : append to $MESH_DISTILLER_OUTPUT_DIR/auto-distilled-YYYYMM.md
# Exit   : always 0
#
# Invocation model:
#   Uses `claude --print` (NOT --bare: --bare skips credential loading and
#   breaks auth). Recursion is prevented by the MESH_DISTILLER_ACTIVE sentinel:
#   the child `claude` inherits it and its own SessionEnd hook exits
#   immediately.
#
# Env vars (all optional, with defaults):
#   MESH_DISTILLER_MIN_ACTIONS  (10)     min logged actions to bother distilling
#   MESH_DISTILLER_MAX_TOKENS   (30000)  truncate log above ~this many tokens
#   MESH_DISTILLER_MODEL        (haiku)  cheap model is enough for distillation
#   MESH_DISTILLER_TIMEOUT_SEC  (60)     claude call timeout
#   MESH_DISTILLER_OUTPUT_DIR   (~/.claude/distilled)      where to append
#   MESH_DISTILLER_ERROR_LOG    (/tmp/distiller-errors.log) error log
#   MESH_SESSION_LOG_DIR        (~/.claude/session-logs)   where logs live
#                               (same variable session-logger.sh writes to)
#
set -uo pipefail

# --- recursion guard: a child `claude` inherits this and must not re-distill ---
if [ -n "${MESH_DISTILLER_ACTIVE:-}" ]; then
  exit 0
fi

# --- config -------------------------------------------------------------------
MIN_ACTIONS="${MESH_DISTILLER_MIN_ACTIONS:-10}"
MAX_INPUT_TOKENS="${MESH_DISTILLER_MAX_TOKENS:-30000}"
MODEL="${MESH_DISTILLER_MODEL:-haiku}"
TIMEOUT_SEC="${MESH_DISTILLER_TIMEOUT_SEC:-60}"
OUTPUT_DIR="${MESH_DISTILLER_OUTPUT_DIR:-$HOME/.claude/distilled}"
ERRLOG="${MESH_DISTILLER_ERROR_LOG:-/tmp/distiller-errors.log}"
LOG_DIR="${MESH_SESSION_LOG_DIR:-$HOME/.claude/session-logs}"

log_err() { printf '%s [distiller] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >>"$ERRLOG" 2>/dev/null || true; }

# --- dependency check ---------------------------------------------------------
if ! command -v jq >/dev/null 2>&1; then
  log_err "jq not found; cannot parse hook input"
  exit 0
fi
if ! command -v claude >/dev/null 2>&1; then
  log_err "claude CLI not found; cannot distill"
  exit 0
fi

# --- read + parse stdin -------------------------------------------------------
INPUT="$(cat 2>/dev/null || true)"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
if [ -z "$SESSION_ID" ]; then
  log_err "no session_id in input"
  exit 0
fi
SID_SHORT="${SESSION_ID:0:8}"

# --- locate the session log (glob across dates, newest wins) ------------------
shopt -s nullglob
matches=("$LOG_DIR"/*-"$SID_SHORT".md)
shopt -u nullglob
if [ "${#matches[@]}" -eq 0 ]; then
  exit 0  # no log: probably a session too short for the logger; not an error
fi
LOGFILE=""
newest=0
for f in "${matches[@]}"; do
  m=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
  if [ "$m" -ge "$newest" ]; then newest="$m"; LOGFILE="$f"; fi
done
[ -f "$LOGFILE" ] || exit 0

# --- count logged actions -----------------------------------------------------
# shellcheck disable=SC2016  # literal markdown backticks, not an expansion
ACTION_RE='^- `[0-9]{2}:[0-9]{2}:[0-9]{2}` \*\*'
ACTIONS=$(grep -cE "$ACTION_RE" "$LOGFILE" 2>/dev/null)
ACTIONS=${ACTIONS:-0}
if [ "$ACTIONS" -lt "$MIN_ACTIONS" ]; then
  exit 0  # trivial session, not worth distilling
fi

# --- read log, truncating if oversized (~4 bytes/token heuristic) -------------
MAX_BYTES=$(( MAX_INPUT_TOKENS * 4 ))
BYTES=$(wc -c <"$LOGFILE" 2>/dev/null | tr -d ' ')
if [ "${BYTES:-0}" -gt "$MAX_BYTES" ]; then
  half=$(( MAX_BYTES / 2 ))
  LOGCONTENT="$(head -c "$half" "$LOGFILE")
[... log truncated to fit token budget ...]
$(tail -c "$half" "$LOGFILE")"
  log_err "session $SID_SHORT log truncated ($BYTES > $MAX_BYTES bytes)"
else
  LOGCONTENT="$(cat "$LOGFILE")"
fi

# --- build prompt -------------------------------------------------------------
read -r -d '' PROMPT <<EOF || true
You will receive a Claude Code session log with timestamped tool invocations (Bash, Write, Edit).

Your job: distill the session into 3-5 concrete operational lessons in bullet format, <=100 words total.

Focus on:
- Decisions made and WHY (not what tool was used)
- Surprising findings or bugs encountered
- Reusable patterns or gotchas
- Skip trivial sessions (exploration, single-command lookups) — respond with literally "SKIP" if not worth distilling

Format:
- Bullet list of 3-5 lessons
- <=100 words total
- Concrete, technical, no fluff
- Match the language of the log

Session log:
$LOGCONTENT
EOF

# --- call claude with a portable timeout ---------------------------------------
# macOS has no coreutils `timeout`/`gtimeout`, so run claude in the background
# with a watchdog. The whole block is wrapped to suppress job-control notices;
# claude's real stderr still goes to $ERRLOG, and timeout is flagged via a file.
OUTFILE="$(mktemp 2>/dev/null || echo /tmp/distiller-out.$$)"
TIMED_OUT="${OUTFILE}.timeout"
RESULT=""
(
  export MESH_DISTILLER_ACTIVE=1
  # background the pipeline directly (no subshell wrapper): $! must be claude's
  # real PID, or the watchdog kills a wrapper and claude keeps running/spending
  printf '%s' "$PROMPT" | claude --print --model "$MODEL" >"$OUTFILE" 2>>"$ERRLOG" &
  inner=$!
  ( sleep "$TIMEOUT_SEC"; kill "$inner" 2>/dev/null; : >"$TIMED_OUT" ) &
  watch=$!
  wait "$inner" 2>/dev/null
  kill "$watch" 2>/dev/null
  wait "$watch" 2>/dev/null
) 2>/dev/null
if [ -f "$TIMED_OUT" ]; then
  log_err "session $SID_SHORT: claude timed out after ${TIMEOUT_SEC}s"
  rm -f "$TIMED_OUT" 2>/dev/null
fi
RESULT="$(cat "$OUTFILE" 2>/dev/null)"
rm -f "$OUTFILE" 2>/dev/null

# trim whitespace
RESULT="$(printf '%s' "$RESULT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [ -z "$RESULT" ]; then
  log_err "session $SID_SHORT: empty response from claude"
  exit 0
fi
if [ "$RESULT" = "SKIP" ]; then
  exit 0  # model judged the session not worth distilling
fi

# --- append distillate (portable mkdir lock for atomicity) --------------------
mkdir -p "$OUTPUT_DIR" 2>/dev/null
YYYYMM="$(date '+%Y%m')"
STAMP="$(date '+%Y-%m-%d %H:%M')"
OUTFILE_MD="$OUTPUT_DIR/auto-distilled-${YYYYMM}.md"
LOCKDIR="${OUTFILE_MD}.lock"

# acquire lock (mkdir is atomic; retry briefly)
locked=0
for _ in $(seq 1 50); do
  if mkdir "$LOCKDIR" 2>/dev/null; then locked=1; break; fi
  sleep 0.1
done
# only clean up a lock we actually own — removing another process's lock
# would break the mutual exclusion this block exists to provide
if [ "$locked" -eq 1 ]; then
  trap 'rmdir "$LOCKDIR" 2>/dev/null || true' EXIT
fi

if [ ! -f "$OUTFILE_MD" ]; then
  {
    printf '# Auto-distilled lessons — %s\n\n' "$YYYYMM"
    printf '> Generated by session-distiller.sh on session close. Not authored by hand.\n\n'
  } >>"$OUTFILE_MD" 2>/dev/null
fi
{
  printf '## %s — session %s (%s actions)\n\n' "$STAMP" "$SID_SHORT" "$ACTIONS"
  printf '%s\n\n---\n\n' "$RESULT"
} >>"$OUTFILE_MD" 2>/dev/null

[ "$locked" -eq 1 ] || log_err "session $SID_SHORT: appended without lock (timeout acquiring)"

exit 0
