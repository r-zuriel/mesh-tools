#!/usr/bin/env bash
#
# dw-monitor.sh — telemetry for subagent (Task/Agent tool) invocations
#
# Claude Code PostToolUse hook (matcher: Task). Records:
#   - timestamp + session + tool
#   - subagent_type used
#   - status (success/failure from tool_response)
#   - short description
#
# Per-day log : $MESH_DW_LOG_DIR/YYYYMMDD.md (one file per day, all sessions)
# Metrics     : $MESH_DW_LOG_DIR/_metrics.json (totals, success rate, breakdowns)
#
# Alerts: if the failure rate exceeds MESH_DW_ALERT_PCT over more than
# MESH_DW_ALERT_MIN invocations, a warning is injected via additionalContext.
#
# Config (env):
#   MESH_DW_LOG_DIR    (~/.claude/dw-logs)   where logs/metrics are written
#   MESH_DW_ALERT_PCT  (30)                  failure-rate % that triggers an alert
#   MESH_DW_ALERT_MIN  (10)                  min invocations before alerting
#
# Requires: jq. Never fails the hook (always exit 0).
# Install: add to .claude/settings.json under hooks.PostToolUse with matcher "Task".

set +e

LOGDIR="${MESH_DW_LOG_DIR:-$HOME/.claude/dw-logs}"
ALERT_PCT="${MESH_DW_ALERT_PCT:-30}"
ALERT_MIN="${MESH_DW_ALERT_MIN:-10}"
mkdir -p "$LOGDIR" 2>/dev/null

input=$(cat 2>/dev/null)

# Portable ISO-ish timestamp (BSD/macOS `date` has no -Iseconds)
now_iso() { date +%Y-%m-%dT%H:%M:%S; }

sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null); [ -z "$sid" ] && sid="nosession"
sid_short=$(printf '%s' "$sid" | cut -c1-8)
tool=$(printf '%s' "$input" | jq -r '.tool_name // "?"' 2>/dev/null)

# Only process the subagent tool. Extend this case if new tool names appear.
case "$tool" in
  Task|Agent) : ;;
  *) exit 0 ;;  # other tools are captured by session-logger.sh
esac

subagent_type=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // "default"' 2>/dev/null)
description=$(printf '%s' "$input" | jq -r '.tool_input.description // ""' 2>/dev/null)

# Status: if tool_response has an error → failure
status="success"
err=$(printf '%s' "$input" | jq -r '.tool_response.error // ""' 2>/dev/null)
[ -n "$err" ] && status="failure"

day=$(date +%Y%m%d)
logfile="$LOGDIR/${day}.md"
ts=$(date +%H:%M:%S)

# Header if the log is new
if [ ! -f "$logfile" ]; then
  {
    echo "# Subagent monitor — ${day}"
    echo ""
    echo "> Records Task/Agent tool invocations."
    echo ""
    echo "| Time | Session | Tool | Subagent type | Status | Description |"
    echo "|------|---------|------|---------------|--------|-------------|"
  } >> "$logfile" 2>/dev/null
fi

# Append row
printf -- '| %s | %s | %s | %s | %s | %s |\n' \
  "$ts" "$sid_short" "$tool" "$subagent_type" "$status" "${description:0:80}" \
  >> "$logfile" 2>/dev/null

# Aggregate metrics (cumulative across all days)
metricsfile="$LOGDIR/_metrics.json"
if [ ! -f "$metricsfile" ]; then
  # shellcheck disable=SC2016  # $fs is a jq variable, not a shell variable
  jq -cn --arg fs "$(now_iso)" '{total:0,success:0,failure:0,by_subagent_type:{},by_tool:{},first_seen:$fs}' \
    > "$metricsfile" 2>/dev/null
fi

# Update metrics atomically (write tmp, then move)
# shellcheck disable=SC2016  # $sub/$t/$st/$ls are jq variables, not shell variables
jq --arg sub "$subagent_type" --arg t "$tool" --arg st "$status" --arg ls "$(now_iso)" '
  .total = (.total + 1)
  | (if $st == "success" then .success = (.success + 1) else .failure = (.failure + 1) end)
  | .by_subagent_type[$sub] = ((.by_subagent_type[$sub] // 0) + 1)
  | .by_tool[$t] = ((.by_tool[$t] // 0) + 1)
  | .last_seen = $ls
' "$metricsfile" > "${metricsfile}.tmp" 2>/dev/null && mv "${metricsfile}.tmp" "$metricsfile" 2>/dev/null

# Alert on high failure rate (integer math — no bc dependency)
total=$(jq -r '.total' "$metricsfile" 2>/dev/null)
failures=$(jq -r '.failure' "$metricsfile" 2>/dev/null)
if [ "${total:-0}" -gt "$ALERT_MIN" ] 2>/dev/null && [ "${failures:-0}" -gt 0 ] 2>/dev/null; then
  # failures/total > ALERT_PCT/100  <=>  failures*100 > ALERT_PCT*total
  if [ $((failures * 100)) -gt $((ALERT_PCT * total)) ] 2>/dev/null; then
    rate=$(( failures * 100 / total ))
    ctx="SUBAGENT MONITOR ALERT: failure rate = ${rate}% (${failures}/${total}). Review ${logfile} and ${metricsfile}. Possible Task/Agent tool degradation."
    # shellcheck disable=SC2016  # $c is a jq variable, not a shell variable
    jq -cn --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}' 2>/dev/null
  fi
fi

exit 0
