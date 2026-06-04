#!/usr/bin/env bash
#
# Tests for session-distiller.sh (T1-T6).
# Uses a fake `claude` on PATH so no real API calls or tokens are spent.
#
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/src/hooks/session-distiller.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { printf 'ok   - %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf 'FAIL - %s\n' "$1"; FAIL=$((FAIL+1)); }

# --- fake `claude` whose behavior is driven by FAKE_CLAUDE_MODE ---------------
FAKEBIN="$TMP/bin"
mkdir -p "$FAKEBIN"
cat >"$FAKEBIN/claude" <<'FAKE'
#!/usr/bin/env bash
# ignore flags, read stdin
cat >/dev/null 2>&1
case "${FAKE_CLAUDE_MODE:-normal}" in
  skip)    printf 'SKIP' ;;
  slow)    sleep 5; printf -- '- lesson after delay' ;;
  empty)   printf '' ;;
  *)       printf -- '- Decision X for reason Y\n- Gotcha Z found\n- Reusable pattern W' ;;
esac
FAKE
chmod +x "$FAKEBIN/claude"
export PATH="$FAKEBIN:$PATH"

# --- helpers -------------------------------------------------------------------
make_log() {  # make_log <sid8> <n_actions>
  local sid="$1" n="$2" dir="$TMP/logs" i
  mkdir -p "$dir"
  local f="$dir/20260101-${sid}.md"
  {
    printf '# Session log — 20260101 (%s)\n\n' "$sid"
    printf '> Automatic black box.\n\n'
    for ((i=0; i<n; i++)); do
      # shellcheck disable=SC2016  # literal markdown backticks, not an expansion
      printf -- '- `10:%02d:00` **Bash** echo action %d\n' "$i" "$i"
    done
  } >"$f"
  echo "$f"
}

run() {  # run <sid> ; sets OUTDIR, returns exit code
  OUTDIR="$TMP/out"
  printf '{"session_id":"%s0000000000000000"}' "$1" \
    | MESH_SESSION_LOG_DIR="$TMP/logs" \
      MESH_DISTILLER_OUTPUT_DIR="$OUTDIR" \
      MESH_DISTILLER_ERROR_LOG="$TMP/err.log" \
      MESH_DISTILLER_TIMEOUT_SEC="${TIMEOUT_OVERRIDE:-60}" \
      bash "$SCRIPT"
}
monthly() { echo "$TMP/out/auto-distilled-$(date '+%Y%m').md"; }

# === Test 1: trivial log (5 actions < MIN) → exit 0, no append ================
make_log "test1aaa" 5 >/dev/null
FAKE_CLAUDE_MODE=normal run "test1aaa"; rc=$?
if [ "$rc" -eq 0 ] && [ ! -f "$(monthly)" ]; then ok "T1 trivial log → no append"; else bad "T1 (rc=$rc)"; fi

# === Test 2: real log (>=10 actions) → distill + append =======================
make_log "test2aaa" 12 >/dev/null
FAKE_CLAUDE_MODE=normal run "test2aaa"; rc=$?
if [ "$rc" -eq 0 ] && grep -q "Decision X" "$(monthly)" 2>/dev/null; then ok "T2 real log → distilled + appended"; else bad "T2 (rc=$rc)"; fi

# === Test 3: timeout → exit 0, error logged, no new append =====================
make_log "test3aaa" 12 >/dev/null
before=$(wc -l < "$(monthly)" 2>/dev/null || echo 0)
FAKE_CLAUDE_MODE=slow TIMEOUT_OVERRIDE=2 run "test3aaa"; rc=$?
after=$(wc -l < "$(monthly)" 2>/dev/null || echo 0)
if [ "$rc" -eq 0 ] && [ "$before" = "$after" ] && grep -q "timed out" "$TMP/err.log" 2>/dev/null; then
  ok "T3 timeout → no append + error logged"
else bad "T3 (rc=$rc, before=$before after=$after)"; fi

# === Test 4: model says SKIP → no append ======================================
make_log "test4aaa" 12 >/dev/null
before=$(wc -l < "$(monthly)" 2>/dev/null || echo 0)
FAKE_CLAUDE_MODE=skip run "test4aaa"; rc=$?
after=$(wc -l < "$(monthly)" 2>/dev/null || echo 0)
if [ "$rc" -eq 0 ] && [ "$before" = "$after" ]; then ok "T4 SKIP → no append"; else bad "T4 (before=$before after=$after)"; fi

# === Test 5: existing file + append keeps format (one header, 2 sections) =====
make_log "test5aaa" 12 >/dev/null
FAKE_CLAUDE_MODE=normal run "test5aaa" >/dev/null
headers=$(grep -c '^# Auto-distilled lessons' "$(monthly)" 2>/dev/null)
sections=$(grep -c '^## ' "$(monthly)" 2>/dev/null)
if [ "$headers" -eq 1 ] && [ "$sections" -ge 2 ]; then ok "T5 append preserves format (1 header, $sections sections)"; else bad "T5 (headers=$headers sections=$sections)"; fi

# === Test 6: race — two parallel runs → both sections, no corruption ==========
make_log "test6aaa" 12 >/dev/null
make_log "test6bbb" 12 >/dev/null
FAKE_CLAUDE_MODE=normal run "test6aaa" >/dev/null &
FAKE_CLAUDE_MODE=normal run "test6bbb" >/dev/null &
wait
both=$(grep -c '^## .*session test6' "$(monthly)" 2>/dev/null)
hdr=$(grep -c '^# Auto-distilled lessons' "$(monthly)" 2>/dev/null)
if [ "$both" -eq 2 ] && [ "$hdr" -eq 1 ]; then ok "T6 race → both appends atomic (1 header)"; else bad "T6 (sections=$both headers=$hdr)"; fi

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
