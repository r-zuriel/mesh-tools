#!/usr/bin/env bash
#
# Smoke tests for the visibility hooks (src/hooks/).
# Feeds synthetic PostToolUse JSON and asserts on the produced logs/metrics.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGGER="$ROOT/src/hooks/session-logger.sh"
MONITOR="$ROOT/src/hooks/dw-monitor.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export TMPDIR="$TMP"  # isolate per-session counter files to this sandbox

PASS=0; FAIL=0
ok()  { printf 'ok   - %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf 'FAIL - %s\n' "$1"; FAIL=$((FAIL+1)); }

if ! command -v jq >/dev/null 2>&1; then echo "jq required for hook tests"; exit 1; fi

# --- session-logger ----------------------------------------------------------
# Each sub-test uses a distinct session_id so the per-session counter file does
# not bleed across cases (in production there is one session_id per session).
logger_input() { printf '{"session_id":"%s","tool_name":"%s","tool_input":{"command":"%s"}}' "$1" "$2" "$3"; }

# 1: writes a log line for a Bash action
SID1="aaaaaaaa-0000-0000-0000-000000000000"
logger_input "$SID1" "Bash" "echo hello" | MESH_SESSION_LOG_DIR="$TMP/s" MESH_CHECKPOINT_EVERY=0 bash "$LOGGER" >/dev/null 2>&1
lf=$(ls "$TMP"/s/*-aaaaaaaa.md 2>/dev/null)
if [ -n "$lf" ] && grep -q '\*\*Bash\*\* echo hello' "$lf"; then ok "logger writes action line"; else bad "logger action line"; fi

# 2: checkpoint injected exactly on the Nth action (EVERY=3)
SID2="bbbbbbbb-0000-0000-0000-000000000000"
inj=""
for i in 1 2 3; do
  inj=$(logger_input "$SID2" "Bash" "cmd$i" | MESH_SESSION_LOG_DIR="$TMP/c" MESH_CHECKPOINT_EVERY=3 bash "$LOGGER")
done
if printf '%s' "$inj" | jq -e '.hookSpecificOutput.additionalContext | test("CHECKPOINT")' >/dev/null 2>&1; then
  ok "logger injects checkpoint on Nth action"; else bad "logger checkpoint injection"; fi

# 3: no checkpoint before the Nth action
SID3="cccccccc-0000-0000-0000-000000000000"
inj2=$(logger_input "$SID3" "Bash" "only-one" | MESH_SESSION_LOG_DIR="$TMP/c2" MESH_CHECKPOINT_EVERY=3 bash "$LOGGER")
if [ -z "$inj2" ]; then ok "logger silent before Nth action"; else bad "logger premature checkpoint"; fi

# 4: never fails even on garbage input
if echo 'not json' | MESH_SESSION_LOG_DIR="$TMP/g" bash "$LOGGER" >/dev/null 2>&1; then
  ok "logger exits 0 on bad input"
else
  bad "logger nonzero on bad input"
fi

# --- dw-monitor --------------------------------------------------------------
SIDM="dddddddd-0000-0000-0000-000000000000"
task_input() { printf '{"session_id":"%s","tool_name":"Task","tool_input":{"subagent_type":"%s","description":"d"}%s}' "$SIDM" "$1" "$2"; }

# 5: records a Task row + metrics
task_input "Explore" "" | MESH_DW_LOG_DIR="$TMP/dw" bash "$MONITOR" >/dev/null 2>&1
mf="$TMP/dw/_metrics.json"
if [ -f "$mf" ] && [ "$(jq -r '.total' "$mf")" = "1" ] && [ "$(jq -r '.by_subagent_type.Explore' "$mf")" = "1" ]; then
  ok "monitor records task + metrics"; else bad "monitor metrics"; fi

# 6: ignores non-Task tools
printf '{"session_id":"%s","tool_name":"Bash"}' "$SIDM" | MESH_DW_LOG_DIR="$TMP/dw2" bash "$MONITOR" >/dev/null 2>&1
if [ ! -f "$TMP/dw2/_metrics.json" ]; then ok "monitor ignores non-Task tools"; else bad "monitor processed non-Task"; fi

# 7: failure-rate alert fires past threshold
DW3="$TMP/dw3"
for i in $(seq 1 12); do
  task_input "x" ',"tool_response":{"error":"boom"}' | MESH_DW_LOG_DIR="$DW3" MESH_DW_ALERT_MIN=10 MESH_DW_ALERT_PCT=30 bash "$MONITOR" >/dev/null 2>&1
done
alert=$(task_input "x" ',"tool_response":{"error":"boom"}' | MESH_DW_LOG_DIR="$DW3" MESH_DW_ALERT_MIN=10 MESH_DW_ALERT_PCT=30 bash "$MONITOR")
if printf '%s' "$alert" | jq -e '.hookSpecificOutput.additionalContext | test("ALERT")' >/dev/null 2>&1; then
  ok "monitor alerts on high failure rate"; else bad "monitor alert"; fi

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
