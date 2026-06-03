#!/usr/bin/env bash
#
# Smoke tests for the mesh file-bus (src/mesh/).
# Runs a full round-trip against a throwaway bus dir — no real inboxes touched.
#
# No pipefail: tests pipe script output into `grep -q`, which closes the pipe on
# first match and would SIGPIPE the producer; assertions below are explicit.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEND="$ROOT/src/mesh/mesh-send.sh"
CHECK="$ROOT/src/mesh/mesh-check.sh"
INIT="$ROOT/src/mesh/mesh-init.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export MESH_BUS_DIR="$TMP/bus"
export MESH_IDENTITY_FILE="$TMP/.mesh-identity"

PASS=0; FAIL=0
ok()  { printf 'ok   - %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf 'FAIL - %s\n' "$1"; FAIL=$((FAIL+1)); }

# 1: empty inbox reports empty
if bash "$CHECK" alice | grep -q "is empty"; then ok "empty inbox reported"; else bad "empty inbox"; fi

# 2: send creates a message file in recipient inbox
dest=$(printf 'hello body' | bash "$SEND" alice bob "First subject")
if [ -f "$dest" ] && grep -q '^from: alice$' "$dest" && grep -q '^# First subject$' "$dest"; then
  ok "send writes frontmatter + subject"; else bad "send writes message ($dest)"; fi

# 3: send refuses empty body
if printf '' | bash "$SEND" alice bob "Empty" >/dev/null 2>&1; then bad "send accepted empty body"; else ok "send rejects empty body"; fi

# 4: send rejects invalid identity
if printf 'x' | bash "$SEND" "Bad Name" bob "X" >/dev/null 2>&1; then bad "send accepted invalid id"; else ok "send rejects invalid identity"; fi

# 5: check lists the new message for bob
if bash "$CHECK" bob | grep -q "First subject"; then ok "check lists new message"; else bad "check list"; fi

# 6: --show prints the full message
msgid=$(basename "$dest" .md)
if bash "$CHECK" bob --show "$msgid" | grep -q "hello body"; then ok "--show prints body"; else bad "--show"; fi

# 7: --read moves message to _read/
bash "$CHECK" bob --read "$msgid" >/dev/null
if [ ! -f "$MESH_BUS_DIR/bob/$msgid.md" ] && [ -f "$MESH_BUS_DIR/bob/_read/$msgid.md" ]; then
  ok "--read moves to _read/"; else bad "--read move"; fi

# 8: inbox empty again after read
if bash "$CHECK" bob | grep -q "is empty"; then ok "inbox empty after read"; else bad "inbox not empty after read"; fi

# 9: --show still finds a read message
if bash "$CHECK" bob --show "$msgid" | grep -q "hello body"; then ok "--show finds read message"; else bad "--show read"; fi

# 10: reply carries in-reply-to header
reply=$(printf 'reply body' | bash "$SEND" bob alice "Re: First" --reply-to "$msgid")
if grep -q "^in-reply-to: $msgid$" "$reply"; then ok "reply sets in-reply-to"; else bad "in-reply-to"; fi

# 11: register + state listing
bash "$INIT" register carol "test agent" >/dev/null
if bash "$INIT" | grep -q "carol"; then ok "register + state lists identity"; else bad "register/state"; fi

# 12: set-default / get-default round-trip
bash "$INIT" set-default alice >/dev/null
if bash "$INIT" get-default | grep -q "^alice "; then ok "set/get default identity"; else bad "set/get default"; fi

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
