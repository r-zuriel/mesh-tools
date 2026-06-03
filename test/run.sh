#!/usr/bin/env bash
#
# Minimal smoke test runner for the F1 scaffold.
# Exits non-zero on first failure. Grows with each component.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/bin/mesh-tools.js"
fail=0

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   - $desc"
  else
    echo "FAIL - $desc"
    fail=1
  fi
}

check "CLI reports a version" node "$CLI" --version
check "CLI prints help" node "$CLI" --help
check "CLI handles 'init' stub" node "$CLI" init

# Unknown command must exit non-zero
if node "$CLI" definitely-not-a-command >/dev/null 2>&1; then
  echo "FAIL - unknown command should exit non-zero"
  fail=1
else
  echo "ok   - unknown command exits non-zero"
fi

if [ "$fail" -ne 0 ]; then
  echo "Some tests failed." >&2
  exit 1
fi
echo "All CLI smoke tests passed."

# Hook smoke tests (require jq; skip cleanly if absent)
if command -v jq >/dev/null 2>&1; then
  echo
  echo "Running hook smoke tests..."
  bash "$ROOT/test/hooks.test.sh" || exit 1
else
  echo "jq not found — skipping hook smoke tests."
fi
