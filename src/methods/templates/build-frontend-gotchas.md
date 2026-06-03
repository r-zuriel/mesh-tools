# Build & frontend gotchas

A pre-flight checklist of recurring gotchas for distributable code, CI pipelines, and frontend rendering. Each entry follows a symptom / cause / fix shape with a generic example. Run through the relevant items before you push, release, or ship a UI change — most of these fail silently or only on someone else's machine.

---

## Frontend (render / UI)

### GF-1 — Three.js: call `setPixelRatio` before `setSize`

**Symptom:** the scene renders pixelated on retina / high-DPI / 4K displays.

**Cause:** `setSize` was called before `setPixelRatio`, so the renderer sized its buffer at the wrong device pixel ratio.

**Fix:** set the pixel ratio first, then the size.

```js
renderer.setPixelRatio(window.devicePixelRatio); // first
renderer.setSize(width, height);                 // then
```

### GF-2 — Three.js: `setSize(w, h, false)` leaves the canvas CSS untouched

**Symptom:** pixelated or stretched canvas; the internal buffer and the displayed element disagree on size.

**Cause:** the third argument to `setSize` (`false`) tells Three.js not to update the canvas CSS, producing a mismatch between the internal drawing buffer and the on-screen display size.

**Fix:** use `true` (the default) so Three.js syncs the CSS, or synchronize the CSS yourself deliberately.

```js
renderer.setSize(width, height, true); // let Three.js update the canvas CSS
```

### GF-3 — Leaflet's internal z-index (~1000) covers fixed navbars

**Symptom:** a `position: fixed` navigation bar disappears behind the map.

**Cause:** Leaflet assigns its internal layers a z-index around 1000, which can sit above fixed page chrome.

**Fix:** create an isolated stacking context on the map container with `isolation: isolate`.

```css
.map-container { isolation: isolate; }
```

### GF-4 — Map attribution is mandatory

**Symptom:** removing the attribution control "to clean up the UI."

**Cause:** tile providers (e.g. OpenStreetMap, CARTO) require visible attribution in their terms of service. Removing it is a ToS violation that risks legal exposure and tile-serving blocks.

**Fix:** never remove the attribution control from Leaflet / MapLibre. Keep it visible and accurate.

---

## Build / deploy / CI

### GB-1 — A transitive dependency can pin your language version

**Symptom:** you cannot lower your project's language version for broader compatibility, even though your own code would compile fine on an older one.

**Cause:** a dependency (often transitive) requires a minimum language version that propagates up to your build. Lowering it breaks the dependency.

**Fix:** check the language-version requirements of your dependencies before committing to a target version. If a dep forces a floor you cannot accept, the choice is to find an alternative dep or accept the higher floor — not to fight the toolchain.

### GB-2 — Secrets: run gitleaks in CI plus a manual grep before pushing

**Symptom:** a credential lands in git history.

**Cause:** no automated secret scan, or relying solely on memory before a push.

**Fix:** run `gitleaks` in CI and do a manual grep for secret patterns before pushing, especially for public repos. A secret committed to a public repo is permanently exposed — it stays in git history even after you delete it, so treat any leak as a rotation event.

### GB-3 — `gitleaks-action@v2` fails on the root commit of a new repo

**Symptom:** the gitleaks CI step fails with `git "ambiguous argument"` and exit 1 on the very first push of a brand-new repo — but there is no actual leak.

**Cause:** `gitleaks-action@v2` scans `commit^..HEAD` by default. On the root commit there is no parent (`commit^`), so the git range is invalid. It is the action being miscalibrated for new repos, not a real finding.

**Fix:** drop the action wrapper and install the gitleaks binary directly, then scan full history from the root.

```yaml
- name: Install gitleaks
  run: |
    curl -sSL https://github.com/gitleaks/gitleaks/releases/download/v8.x.x/gitleaks_..._linux_x64.tar.gz | tar xz
    sudo mv gitleaks /usr/local/bin/
- name: Scan
  run: gitleaks detect --source . --redact --verbose --exit-code 1
```

`gitleaks detect --source .` scans full history from the root rather than an incremental diff, so it works from the first commit.

### GB-4 — `shellcheck SC2016` false positives: literal backticks and jq variables

**Symptom:** SC2016 ("expressions don't expand in single quotes") fires on lines that are intentionally correct.

**Cause:** two common legitimate cases:

1. **Literal backticks inside a `printf` of markdown** — e.g. `printf '... \`SC2016\` ...'`. The backticks are markdown, not command substitution.
2. **jq variables inside single quotes** — e.g. `jq '$c + $sub'`. Here `$c`, `$sub`, `$fs` are jq language variables, not shell variables.

**Fix:** disable the check surgically, per line, never globally.

```bash
# shellcheck disable=SC2016
printf '... `code` ...'

# shellcheck disable=SC2016
jq '$c + $sub' < data.json
```

Do not put `# shellcheck disable=SC2016` at script level — you would lose coverage of real SC2016 findings.

### GB-5 — `date -Iseconds` does not exist on BSD/macOS

**Symptom:** a script works in CI (Ubuntu) but fails locally on macOS, often silently or with a date error.

**Cause:** `date -Iseconds` is GNU-only. The BSD `date` shipped with macOS does not support it.

**Fix:** use a POSIX format string, or fall back to `gdate` when available.

```bash
# NOT portable
date -Iseconds

# Portable (POSIX)
date -u +"%Y-%m-%dT%H:%M:%SZ"

# Or prefer gdate if present
command -v gdate >/dev/null && gdate -Iseconds || date -u +"%Y-%m-%dT%H:%M:%SZ"
```

### GB-6 — Avoid `bc` in portable scripts; use shell integer arithmetic

**Symptom:** a script fails on a machine where `bc` is not installed.

**Cause:** `bc` is not preinstalled by default everywhere (notably some macOS versions) and adds an external dependency.

**Fix:** use shell arithmetic expansion for integers; use `awk` (always preinstalled) when you need floats.

```bash
# Requires bc
echo "$a + $b" | bc

# POSIX, no external dependency
echo $((a + b))

# Floats without bc, using awk
awk "BEGIN{print $a + $b}"
```

### GB-7 — `fail-loud` CLIs vs `exit 0` hooks (design intent)

**Symptom:** a hook (e.g. a git or editor hook) blocks the user's real operation when its own logic fails; or a CLI silently swallows an error the user needed to see.

**Cause:** the binary's purpose was not distinguished. A CLI and a hook want opposite error-handling.

**Fix:** decide which kind of tool you are writing and apply the matching policy.

| Type | Behavior | Reason |
|---|---|---|
| **CLI** (interactive tool) | `set -euo pipefail` + `trap ERR` + non-zero exit on failure | An interactive user needs to see the error clearly |
| **Hook** (logger, monitor, sync) | `set -u` only + always `exit 0` + log errors silently | A hook must never fail the real operation it is attached to |

```bash
# WRONG — set -e in a hook can block the user's workflow
#!/bin/bash
set -euo pipefail
some_command   # if it fails, it blocks the host operation

# RIGHT — resilient hook
#!/bin/bash
set -u
some_command 2>>"$LOG_DIR/errors.log" || true
exit 0
```

If a script's intent is ambiguous, state it explicitly in the pre-flight before writing it.

### GB-8 — Validating input is not validating a configurable path (layered threat model)

**Symptom:** an input's name/syntax is validated, but a configurable destination path is not — letting a caller write somewhere privileged.

**Cause:** input validation and path validation are different concerns. An environment variable that accepts an arbitrary path (e.g. `APP_OUTPUT_DIR=/anything`) bypasses syntax checks entirely.

**Fix:** apply at least one mitigation, treating the threat model as layered (validating the input is necessary but not sufficient when there are configurable extension points).

```bash
# Input validation (identifier syntax) — necessary
echo "$id" | grep -qE '^[a-z0-9_-]+$'

# Path validation MISSING — the env var could point at /etc/ → privileged write
mkdir -p "$BASE_DIR/$id"   # does not validate $BASE_DIR
```

1. **Hardcode a safe default** and ignore the env var in production.
2. **Validate an allowed prefix:** `case "$BASE_DIR" in /home/*|/tmp/*) ;; *) exit 1 ;; esac`.
3. **Document the threat model** in the project's `SECURITY.md`: state that the path is operator-configurable and that whoever controls the env var can write to any path.

For a single-user CLI, documenting the threat model can be an acceptable mitigation; for a multi-tenant service, prefer hardcoding or prefix validation.

---

*Harvested from real build/frontend work, anonymized for public distribution. Feedback welcome via Issues.*
