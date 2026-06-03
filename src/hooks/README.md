# Visibility hooks

Session-level observability for Claude Code, implemented as `PostToolUse` hooks.

- **`session-logger.sh`** — appends every Bash/Write/Edit action to a per-session
  black-box log and injects a checkpoint reminder every N actions.
- **`dw-monitor.sh`** — records Task/Agent (subagent) invocations, aggregates
  success/failure metrics, and alerts when the failure rate is high.

Both require [`jq`](https://jqlang.github.io/jq/) and always exit 0 (a hook that
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
    ]
  }
}
```

A future `mesh-tools init` will automate this wiring.
