# Visibility hooks

Session-level observability for Claude Code. Ships in **v0.1.0**.

Planned contents:

- `session-logger.sh` — black-box log of Bash/Write/Edit actions plus periodic
  checkpoint reminders for long sessions.
- `dw-monitor.sh` — telemetry for Task/Agent (subagent) invocations, with
  aggregated failure-rate alerting.

Each script will document its trigger (hook event), environment variables, and
exit codes inline. Placeholder directory in the current scaffold.
