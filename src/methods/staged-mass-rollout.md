# Staged mass rollout

A method for applying an **identical change across many hosts** (N ≥ 5) when the change touches sensitive dimensions: credentials, production configuration, customer data, security or monitoring agents. Running the change against all hosts at once amplifies risk by N; running it one-by-one with a human checkpoint every time is slow and fatiguing. This method threads the needle: prove the change on a single pilot, gate escalation behind an explicit human checkpoint, then roll out in small idempotent blocks with state capture and end-to-end validation.

The value is not in any single step — peer review, step-by-step execution, and idempotent scripting all exist independently. The value is the **integration**: the steps together form one coherent flow for risky bulk changes.

## When to use

- 5 or more target hosts receiving an identical change.
- The change touches: credentials, authorization, SSH daemon config, sudoers, secrets, certificates, production networking, firewall rules, SIEM/monitoring agents.
- There is an uncertainty dimension the operator **cannot resolve with code alone** (contractual ownership, regulated data, inter-host dependencies).
- A human plus an assistant are driving the rollout — not blind automation.

## Steps

### 1. Peer review of the proposal

Before touching anything, send the proposal to a reviewer (a second person, or a dedicated adversarial reviewer role). The proposal must contain:

- Explicit premise ("I am going to load key X onto N containers because...").
- Target universe (an explicit list, or an inclusion criterion).
- Step-by-step plan.
- Documented rollback.
- Identified risks.
- Expected verification.

Wait for the verdict before touching anything. If approved with mitigations, apply **all** of them before executing. For especially high-risk changes, consider a plan-mode or dry-run gate as a second safety net on top of the review.

**Pre-flight gotcha check (gates step 2).** Before the pilot, enumerate the known gotchas for this kind of change. Consult any subsystem notes/lessons, hard rules from your operations playbook, and produce a canonical table:

```markdown
| Gotcha / discipline | Applies (yes/no/maybe) | Reason / mitigation |
|---|:---:|---|
| ... | ... | ... |
```

Without this table, the pilot does not run. The pre-flight check is part of the peer review.

> **Code-change variant.** If the "mass" change is *code* rather than live infrastructure, isolate the pilot in a separate working tree (e.g. a git worktree) so the main branch stays green. The pilot happens in the isolated tree; the bulk change merges to main only if the pilot passes. This does not apply to live-infra rollouts (loading SSH keys across N hosts operates running systems, not repositories); it does apply to mass code refactors, framework migrations, or rolling a new pattern across N files in one repo.

### 2. Pilot on one host

Pick the host with the smallest blast radius. Typical criteria:

- Low-tier / non-critical (not a tier-0 or tier-1 system).
- No active downstream dependencies.
- The operator can reach it directly to verify.
- If it fails, rollback needs no external coordination.

Run the idempotent change on that single host and capture:

- `>>> PRE-STATE` (line count / file hash / relevant output).
- `>>> CHANGE` (`RESULT=INSERTED | ALREADY_PRESENT | FAILED`).
- `>>> POST-STATE` (same shape as pre, directly comparable).
- `>>> VALIDATION` from the real origin — from where the change must *serve*, not from where it was applied (e.g. from the workstation, not from a jump host).

**2.a — Prove idempotency empirically by rerun (3+ runs).** Reading `grep -qF` in the source is not enough. Run the script on the pilot host **three or more times in a row** and show the result: 1st `RESULT=INSERTED`, 2nd-Nth `RESULT=ALREADY_PRESENT`. That visible sequence gives confidence that code inspection cannot.

**2.b — Anchored heredoc is mandatory for multi-line remote execution** (`ssh ... <<EOF`, `exec ... bash <<EOF`). Use `<<'REMOTE'` with single quotes so `$(...)` and `$VAR` are **not** expanded by the local shell. A real anonymized incident traced a bug to `$(wc -l file)` expanding on the local workstation instead of on the remote host.

```bash
# WRONG — expands locally
ssh "$host" "exec_remote bash <<EOF
count=$(wc -l /path/to/file)
echo \$count
EOF"

# RIGHT — quote anchors; everything runs remotely
ssh "$host" "exec_remote bash <<'REMOTE'
count=\$(wc -l /path/to/file)
echo \$count
REMOTE"
```

### 3. Explicit human checkpoint

Stop here. Do **not** escalate to the bulk rollout without an explicit go-ahead. Communicate:

- Pilot status: succeeded / failed / partial.
- Exactly what was done (no ambiguous jargon).
- What validation was run.
- A copy-paste-ready rollback command.
- Options: (a) proceed to bulk, (b) stop and keep only the pilot, (c) revert the pilot.

Use neutral language in sensitive operations — "inject" sounds aggressive; prefer "add", "load". Apply this **during** execution, not only in the final report: the moment of anxiety arrives while logs are scrolling, not afterward.

### 4. Categorize with human validation

Before the bulk rollout, build a table of N hosts against inclusion/exclusion dimensions.

**Default is INCLUDE**, not exclude — start from "everything this team operates is in scope" and remove specific exceptions. The filter direction matters: an exclude-by-default calibration leads to under-coverage and ad-hoc reasoning.

A canonical bucketing:

```markdown
| Bucket | Count | Action (default) |
|---|---:|---|
| Operated by us (default) | X | Apply — we are operationally responsible |
| Probably operated by us (confirm) | Y | Confirm one-by-one; default INCLUDE |
| Sister-org / managed customer | E | Apply — under operational management |
| Uncertain (responsibility unconfirmed) | Z | Confirm; default INCLUDE if monitored/managed |
| Excluded by specific exception | W | DO NOT TOUCH — requires one of the reasons below |
```

**The only legitimate reasons to exclude:**

1. **Data owner is a regulated customer** (government, banking, healthcare) — legal escalation required before destructive change. Monitoring and read access usually remain fine.
2. **An explicit standing order** ("do not touch instance X") — this takes precedence over the general rule.
3. **The host is not operated by us** — out of scope (this is non-applicability, not exclusion).

**Not legitimate reasons to exclude:** "our hardware but a customer's app", "the host name looks like a customer's", "no explicit contractual sign-off" (an operations contract may already cover it by default).

The human validates the table before proceeding. Validation can move a host from uncertain to included, from uncertain to excluded (a standing order), or from included to excluded (regulated data needing a legal flag first). Do not assume.

### 5. Bulk rollout, block by block, idempotent

Script design:

1. **Idempotency is mandatory.** `grep -qF <pattern> || append` before modifying. Re-running must not duplicate or break anything.
2. **Permissions enforced before and after** (e.g. `chmod 700` on the SSH dir, `chmod 600` on the key file).
3. **Pre and post state per host captured to a CSV log** or equivalent.
4. **Small blocks.** Execute in blocks of ten hosts or fewer, review the result, then escalate to the next block.
5. **No bypass of protective mechanisms.** Use the official path (e.g. execute from the parent host, not `ssh-keygen` over an existing key).
6. **Legible output.** `>>> SECTION` markers separating states.
7. **Cross-platform care.** Some tools differ across platforms (for example, `timeout` is absent on macOS by default; a portable substitute is `perl -e 'alarm shift; exec @ARGV' N CMD`).

**5.a — Authorized hook bypass.** If a safety hook blocks execution because a pattern matched (e.g. "authorized_keys" triggers a credential-safety guard), do not silently ignore it. The correct pattern is to have the human run the script through the explicitly authorized bypass and record in the work-log that the hook fired and the bypass was explicit.

**5.b — Detect non-uniform service ports.** In heterogeneous fleets, the SSH daemon may listen on a mix of ports (a standard port and one or more non-standard ports) with no obvious pattern. Assuming one port breaks validation. After the change, run an independent sweep that probes each of the fleet's known ports and report OK on detecting the service on any of them.

### 6. Granular validation from the real origin

For each host in the executed block, validate from where the change must *serve*, not where it was applied:

- If you loaded a workstation's key onto a container via its parent host, validate `ssh -i <key> user@<container-ip>` **from the workstation**, not via remote-exec from the parent.
- If you opened a firewall rule for service X, validate the service from the real client, not from the firewall.
- If you changed monitoring config, validate that the alert reaches the SIEM, not that the agent reports "OK".

**6.a — Distinguish "critical operation OK" from "post-validation OK".** Report both metrics separately. In a real anonymized incident the critical operation was 100% successful (all hosts INSERTED) but the validator reported several false failures **due to a validator bug** (assumed port), not an operation failure. Reporting a bare "11 FAIL" without that distinction alarms people and triggers needless rollbacks.

```
Critical operation:  26/26 OK  (100% INSERTED)
Post-validation:     15/26 OK  <- failures here may be a validator bug
                               <- INVESTIGATE before rollback
```

If the numbers differ, **investigate the validator before reverting the operation**.

**6.b — A stop-check between phases can DISCOVER latent bugs, not just confirm.** Granular validation between phases does more than confirm the change worked — it can reveal **new, related** bugs that were not in the original proposal. In a real anonymized incident, a mid-rollout stop-check showed one host fixed but another still failing; investigation surfaced a latent bug (a `return` that should have been a `continue` in a checker loop) that the original plan never touched but which was the actual cause of the reported symptom.

Implications:
- Design stop-checks to ask *"what evidence would confirm or refute my causal model of the fix"*, not just *"did my change get applied"*.
- If the stop-check refutes the causal model (change applied, symptom persists on a subset), **investigate** before moving to the next phase — a latent bug may hide there.
- If a new bug emerges, re-classify severity and decide whether to re-approve the new phase with the reviewer or whether it fits the already-approved scope.

Anti-pattern: assuming "stop-check OK" means "the whole problem is solved". It only means "this specific change worked on this specific surface". If the original symptom persists elsewhere, there is a latent bug.

### 7. Triple close: document + validate + acknowledge

Three actions, not one. "Close defensively with a note" is insufficient.

**7.a — Document.** Open the work-log *before* the bulk rollout (defensive). Record scope, exclusions, technical procedure, controls applied, risks mitigated, and both bulk and individual rollback. State the note as OPEN with an explicit checklist of close criteria. Close it only when those criteria are met.

**7.b — Validate the close.** Before marking closed, verify each item:
- [ ] Bulk script executed on every host in scope (count = scope count).
- [ ] Results captured in CSV with each host and outcome.
- [ ] Granular validation OK per host (from the real origin; critical-vs-validation distinction applied).
- [ ] Surprise cases documented (unexpected category, script failure, unresponsive host).
- [ ] Rollback executed, or documented as not needed.
- [ ] Final results table added to the note.

**7.c — Acknowledge the review loop.** Close the loop with the reviewer who approved the proposal. Send: final result (INSERTED / ALREADY_PRESENT / FAILED counts), whether all mitigations were applied, surprise cases that affected the plan, and any deviation from the approved plan with its reason. Without an acknowledgment, the review cycle is incomplete and auditability suffers.

**7.d — Summary of gotchas applied.** Append to the work-log and the acknowledgment:

```markdown
### Disciplines applied (declared pre-flight + executed)
- ...

### Disciplines skipped (declared possible, not activated)
- ...

### New gotchas / disciplines that emerged
- ...

### Application metric
- Pre-flight coverage: N/M (target >= 80%)
```

New gotchas feed back into the knowledge base and into refining this method for the next run.

### 8. Propagate the lessons

After closing, propagate lessons to wherever they will be reused: durable subsystem notes (so the next session has context without re-reading the whole note), a portable knowledge base for the abstract pattern (so the lesson survives a context change), the operational record for the specific contextualized case, and a heads-up to whoever curates documentation and methods. Do this **after** the review acknowledgment (7.c), not in parallel — the acknowledgment may include refinements that change what you propagate.

## When NOT to use

- N < 5 — a simple step-by-step procedure is enough.
- Fully reversible, read-only changes (audit, inventory) — a parallel script plus a post-mortem suffices.
- Changes on non-sensitive hosts where the difference between one host and another does not matter.
- An existing CI/CD pipeline already guarantees the same flow.

## Example

A team needs to load a new SSH public key onto roughly forty containers spread across several parent hosts, so operators can reach them from a managed workstation. The fleet mixes internally-operated containers, a sister-organization's containers, and a few belonging to a regulated client.

1. The proposal goes to a reviewer: premise, the full target list, the idempotent script, rollback, risks, and expected verification. The reviewer vetoes one container (a regulated-client listener) pending legal escalation and asks for a categorization table.
2. The change is piloted on one low-tier test container and run five times — first run INSERTED, next four ALREADY_PRESENT — proving idempotency.
3. The operator pauses at the human checkpoint; the person driving asks to slow down. Good — that is the checkpoint working.
4. The categorization table is built: internal containers and the sister-org containers default to INCLUDE; the regulated-client listener is excluded by legal exception; lab instances are excluded by an explicit standing order. Final scope: 26 containers.
5. The bulk script runs in blocks, capturing pre/post state per host to CSV.
6. Validation runs by SSHing directly from the workstation to each container. The critical operation is 26/26 INSERTED; the first validation pass shows 15/26 because the validator assumed a single SSH port. A multi-port sweep resolves the false failures — no rollback needed.
7. The work-log is closed against its checklist, and the result is acknowledged back to the reviewer.
8. Lessons (the heredoc-expansion bug and the port-assumption bug) are propagated to the knowledge base.

Outcome: 26/26 applied, zero rollbacks, roughly 1h20m total — of which only ~15% was actual command execution; the rest was conversation, classification, and documentation.

## Variants

**Credential loading.** The archetypal case. Data ownership decides the buckets in step 4; an automatic veto applies to regulated-client owners absent legal escalation.

**Rotating an existing certificate or key.** Differs from loading: there is a **lock-out** risk if the new key fails and the old one is already removed. Extra rule — do not remove the old key until granular validation passes *and* a waiting window (24h or more) has elapsed. Never guess or regenerate credentials.

**Monitoring-agent rollout.** The bulk change alters the behavior of existing hosts (more logs, more CPU). Add a success metric: the agent must report to the SIEM, not merely be "installed". Rollback means fully purging the agent, not just stopping the service.

## Quality metrics

- Time between step 1 (proposal) and step 5 (bulk): at least 30 minutes — do not rush the human checkpoint.
- Reviewer mitigations: 100% applied before step 5.
- Idempotency validated: a rerun of the pilot reports ALREADY_PRESENT, not INSERTED.
- Granular validation: 100% of scope validated from the real origin.
- Rollback executable: script + individual command + estimated time documented **before** step 5.

## Why this method (a meta-lesson)

An early calibration of step 4 inherited an exclude-by-default stance for "apparent external customer". That was wrong: when a team is the operational administrator of everything it monitors, the default access answer is *yes*, with exceptions limited to regulation plus explicit standing orders.

The meta-lesson: when a method integrates a pattern emitted by another role (for example, an adversarial reviewer), validate the operational default with the decision-maker **before** treating it as stable. The reviewer's technical analysis can be correct *and* its operational conclusion mis-calibrated at the same time.

---
*Method harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
