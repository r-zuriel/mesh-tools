# The 4 checks — before any destructive operation

A short protocol of four questions (plus a few situational extras) that an
operator **must** answer *before* running any destructive or high-impact command
against a live system. It exists to turn a reflexive "just run it" into a
deliberate, reversible action.

The method was born from an anonymized real incident: a single destructive
command, executed late in a long session, caused real data loss. The technical
fix afterward was trivial; the expensive part was that no one had paused to ask
what the command actually did and how to undo it. These four questions are that
pause, made repeatable.

## When to use

Apply it whenever you are about to run a command that can irreversibly change or
destroy state. Common triggers:

- Filesystem / data: `rm -rf`, `dd`, `mkfs`, `tune2fs`, `e2fsck`, `truncate`
- System lifecycle: `reboot`, `shutdown`
- Edits to sensitive paths: `/etc/`, `/boot/`, `~/.ssh/`, certificates, `.env`
- Virtualization / storage: container/VM destroy, volume/pool destroy
- Containers: `docker rm` / `docker prune`
- Orchestration: `kubectl delete pv/pvc/ns`
- Databases: SQL `DROP` / `TRUNCATE`
- Version control: `git push --force`, `git reset --hard`, `git branch -D`
- Package management: distribution upgrade, `purge`
- Infrastructure-as-code: `terraform destroy`
- Networking: `iptables -F`

Trigger verbs in a request are also a signal: *delete, wipe, reset, regenerate,
reinstall, migrate, destroy, tear down, purge.*

A practical rule: if you are unsure whether a command qualifies, treat it as if
it does. This pairs well with an automated pre-execution guard hook that flags
known destructive patterns — but the questions are the point, not the tooling.

## The four checks

Order matters. Answer each one out loud (or in writing) before pressing Enter.

```
1. What does this command do, EXACTLY?
   Parse every flag. Name the precise files / resources it touches.

2. What is the blast radius — the side effects?
   Which other systems, users, or data are affected if it succeeds,
   and if it fails partway through.

3. How will I detect failure fast — not days later?
   Which metric, alert, or log to check immediately after execution.

4. What is the rollback?
   The exact command, the estimated time to apply it,
   and what gets lost along the way.

```

For each check, think in terms of:

- **What it does** — the literal effect of the command as written, flags
  included. Most accidents are a misread flag.
- **Effects** — the blast radius beyond the obvious target: shared mounts, other
  tenants, dependent services, replication.
- **How it fails** — the failure mode and its earliest observable symptom, so a
  silent or partial failure does not go unnoticed.
- **Rollback** — a concrete recovery path you have *before* you act, including
  what is unrecoverable.

If you cannot answer check 4 with a real command, you do not have a rollback —
stop and create one (snapshot, backup, config export) first.

## The extras ("++")

Situational checks layered on top of the four when conditions apply:

| When | Additional check |
|---|---|
| Touches an ext4 filesystem | Run `e2fsck -n` before and after |
| Touches production | Confirm a current backup of the host + a defined change window |
| Touches a critical host | Notify the team in the relevant channel first |
| Touches credentials | Apply your credentials-safety rule too — never guess or rotate secrets without an explicit order and a rollback plan |
| Long session + late hours + destructive op | **Blocking fatigue condition**: defer to the next day unless an explicit override is given |
| Mass / fleet operation (e.g. `rsync --delete`, fleet update) | Pilot on a single host first |
| No freshly validated runbook | Switch to an explicit step-by-step procedure (one command per step) |

The fatigue condition deserves emphasis. The originating incident happened after
many hours of accumulated changes, late at night — exactly the state in which
judgment degrades and a destructive command is most dangerous. When fatigue,
duration, late hours, and an upcoming destructive operation coincide, the safe
default is to stop and resume rested.

## When NOT to use

The protocol is for destructive change, not for everything. Skip it for:

- Pure reads: `cat`, `ls`, `grep`, `ps`.
- Safe idempotent commands: `mkdir -p`, `chmod +x`, `git status`.
- Pre-change safety steps themselves: taking a backup, a config export, a
  snapshot.

There is also a **lite** variant for simple, well-bounded operations (for
example, extending a logical volume on a fresh disk, or adding a user): answer
only check 4 (rollback) plus a minimal safety net. Do not let ceremony slow down
genuinely low-risk, well-understood work — the goal is calibrated caution, not
universal friction.

## Example

A synthetic walkthrough. You intend to reclaim space by deleting an old data
directory on a production host:

```
$ rm -rf /srv/data/archive-2023
```

Running the four checks:

1. **What it does** — recursively, forcibly deletes everything under
   `/srv/data/archive-2023`. No prompt, no trash. Double-check the path has no
   trailing-space or glob surprise; `/srv/data/archive-2023/` vs a typo'd
   `/srv/data /archive-2023` are very different.
2. **Effects** — `archive-2023` is bind-mounted into two running containers on
   `host-a`. Deleting it under them can crash both. Blast radius is wider than
   the directory.
3. **How it fails** — if a process holds files open, space is not freed until
   the process restarts; the "failure" is silent. Watch `df -h` and the
   container logs immediately after.
4. **Rollback** — there is none for `rm -rf`. So: take a snapshot or `tar` the
   directory to separate storage first, confirm the archive is readable, *then*
   delete. Recovery time from the snapshot: a few minutes; without it: data is
   gone.

Outcome: the bare `rm -rf` is replaced by *quiesce the containers → snapshot →
delete → verify*. The four questions turned an irreversible command into a
reversible procedure.

---
*Method harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
