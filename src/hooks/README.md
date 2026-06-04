# Visibility hooks

Session-level observability for Claude Code.

- **`session-logger.sh`** (`PostToolUse`) — appends every Bash/Write/Edit action
  to a per-session black-box log and injects a checkpoint reminder every N
  actions.
- **`dw-monitor.sh`** (`PostToolUse`) — records Task/Agent (subagent)
  invocations, aggregates success/failure metrics, and alerts when the failure
  rate is high.
- **`session-distiller.sh`** (`SessionEnd`) — on session close, compresses the
  black-box log into 3-5 concrete operational lessons via `claude --print` and
  appends them to a monthly distillation file.

All require [`jq`](https://jqlang.github.io/jq/) and always exit 0 (a hook that
breaks is worse than the problem it solves).

## session-logger.sh

Writes `YYYYMMDD-<session>.md` under the log dir, one line per action:

```
- `14:03:21` **Bash** npm test
- `14:03:48` **Edit** src/index.js
```

Every N actions it emits `additionalContext` asking the agent to pause and
summarize progress — this counters loss of clarity in long sessions.

| Env | Default | Purpose |
|---|---|---|
| `MESH_CHECKPOINT_EVERY` | `15` | actions between checkpoints; `0` disables |
| `MESH_SESSION_LOG_DIR` | `~/.claude/session-logs` | where logs are written |

## dw-monitor.sh

Writes a daily Markdown table of subagent invocations and a cumulative
`_metrics.json`. Injects a warning when the failure rate crosses a threshold.

| Env | Default | Purpose |
|---|---|---|
| `MESH_DW_LOG_DIR` | `~/.claude/dw-logs` | where logs/metrics are written |
| `MESH_DW_ALERT_PCT` | `30` | failure-rate % that triggers an alert |
| `MESH_DW_ALERT_MIN` | `10` | minimum invocations before alerting |

## session-distiller.sh

Raw session logs are long and rarely re-read. The distiller turns each closed
session into knowledge you actually revisit: on `SessionEnd` it reads the
black-box log written by `session-logger.sh`, asks Claude (a cheap model) for
3-5 concrete lessons (≤100 words), and appends them to
`auto-distilled-YYYYMM.md`:

```
## 2026-01-15 18:42 — session a1b2c3d4 (37 actions)

- Chose mkdir-based locking over flock: flock is absent on macOS.
- `grep -c` exits 1 on zero matches — don't chain `|| echo 0` after capturing.
- ...
```

Design constraints (deliberate):

- **Never touches Claude Code's native memory** or `MEMORY.md` — output goes to
  a separate file you review on your own terms.
- **Skips trivial sessions** (fewer than `MESH_DISTILLER_MIN_ACTIONS` logged
  actions), and honors the model answering `SKIP`.
- **Recursion-safe**: invoking `claude --print` spawns a child session whose own
  `SessionEnd` would re-trigger the hook; the `MESH_DISTILLER_ACTIVE` sentinel
  env var makes the child exit immediately. Do NOT use `claude --bare` for
  this — it skips credential loading, not just hooks, and fails with
  "Not logged in".
- **Portable**: no `timeout`/`gtimeout` (background watchdog instead), no
  `flock` (atomic `mkdir` lock), works on macOS and Linux.

| Env | Default | Purpose |
|---|---|---|
| `MESH_DISTILLER_MIN_ACTIONS` | `10` | min logged actions to bother distilling |
| `MESH_DISTILLER_MAX_TOKENS` | `30000` | truncate the log above ~this many tokens |
| `MESH_DISTILLER_MODEL` | `haiku` | model passed to `claude --print` |
| `MESH_DISTILLER_TIMEOUT_SEC` | `60` | claude call timeout |
| `MESH_DISTILLER_OUTPUT_DIR` | `~/.claude/distilled` | where distillates are appended |
| `MESH_DISTILLER_ERROR_LOG` | `~/.claude/distiller-errors.log` | error log |
| `MESH_SESSION_LOG_DIR` | `~/.claude/session-logs` | where session logs live (shared with session-logger) |

Requires the `claude` CLI authenticated on the machine (it reuses your existing
session — no API key to manage).

### Cost & sensitivity

- Each distillation is **one `claude --print` call billed to your own Claude
  account**: at most `MESH_DISTILLER_MAX_TOKENS` (~30k) input tokens on a cheap
  model (default `haiku`) producing a ~100-word output — a fraction of a cent
  per session at current pricing.
- Sessions below `MESH_DISTILLER_MIN_ACTIONS` are skipped with no call at all,
  and the timeout kills the claude process itself, so it is a real cost cap.
- To stop distilling entirely, remove the `SessionEnd` entry from your
  `settings.json`.
- Distillates may quote fragments of your session log (hostnames, paths,
  commands). Treat the output dir (`~/.claude/distilled/` by default) with the
  same sensitivity as the session logs it derives from.

## Install

Copy the scripts somewhere on disk, make them executable, and reference them in
your `.claude/settings.json`:

```jsonc
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash|Write|Edit",
        "hooks": [
          { "type": "command", "command": "/path/to/session-logger.sh", "timeout": 5 }
        ]
      },
      {
        "matcher": "Task",
        "hooks": [
          { "type": "command", "command": "/path/to/dw-monitor.sh", "timeout": 5 }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          { "type": "command", "command": "/path/to/session-distiller.sh", "timeout": 90 }
        ]
      }
    ]
  }
}
```

Back up your `settings.json` before editing it. Use `SessionEnd` for the
distiller — `Stop` fires on every turn and would re-distill the same log
repeatedly.

A future `mesh-tools init` will automate this wiring.
