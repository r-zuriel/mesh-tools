# Template — mass-change work-log (with peer-review)

## When to use

Use this when you will run an **identical change across many hosts** (rule of thumb: 5 or more) that crosses sensitive dimensions: credentials, production configs, or customer data.

This is a **defensive** template. **Open the log BEFORE the change**, not after. It records scope, exclusions, controls, risks, and rollback up front, and it CLOSES only when every explicit closeout criterion is satisfied.

| Case | Use |
|---|---|
| Reactive incident, one-off fix, deploy to a single host | A simple operational work-log |
| Identical change across 5+ hosts crossing sensitive dimensions | **This template** |
| Multi-phase migration across N hosts | This template + one work-log per phase |
| Read-only audit/inventory | A different template (inventory/audit) |

---

## Template (copy-paste)

```markdown
## CHANGE-{{TYPE}}-{{NUM}}

**Origin:** {{where the change is executed from — e.g. operator workstation, identified key/credential}}
**Target hosts:** {{N hosts across M clusters — granular list below}}
**Type:** {{short description of the change — e.g. "bulk SSH public-key load"}}
**Rationale:** {{1-2 lines — what operational problem this solves}}
**Authorized by:** {{owner/responsible party}} — explicit order on record
**Peer-review:** reviewer msg-id `{{REVIEW-MSG-ID}}` — APPROVED / APPROVED-WITH-MITIGATIONS {{M1..MN}}
**Status:** {{OPEN until closeout criteria met | CLOSED}}

---

### {{Specific authorized change}}

{{Public key, command, config diff, firewall rule, etc. — exact text}}

Fingerprint or hash (if applicable): `{{SHA256 hash}}`

---

### Motivation

{{Why this change. What operational problem it solves. What prior context motivated it
(link to a sweep / incident / ticket). 3-5 lines.}}

---

### Final scope (N hosts — classified into buckets)

State the operating premise up front, e.g.:
*"We administer everything we monitor — default access is YES. Exceptions = regulation + explicit owner order."*
Adjust the premise to your own operating model before using.

**Bucket — In scope, default ACCESS:**
- {{host}}: {{container}}/{{VM}} {{name}} (we are operationally responsible)

**Bucket — Probably in scope (confirm operational responsibility):**
- {{host}}: {{container}}/{{VM}} {{name}} ({{reason}})

**Bucket — Sister entity / operated-on-behalf (confirmed with owner):**
- {{host}}: {{container}}/{{VM}} {{name}} ({{relationship}})

**Bucket — Responsibility NOT confirmed (case by case):**
- {{host}}: {{container}}/{{VM}} {{name}} ({{clarify with owner whether in scope}})

**Bucket — Excluded by specific exception:** see EXCLUSIONS, with a mandatory reason from the legitimate set.

**Pilot run executed:** {{host}} {{container}}/{{VM}} {{name}} — RESULT={{INSERTED|ALREADY_PRESENT|FAILED}},
validated {{how}}. **Reruns for visible idempotency:** N runs, 1st INSERTED + (N-1) ALREADY_PRESENT.

---

### EXCLUSIONS (DO NOT TOUCH — mandatory reason from the legitimate set)

**Legitimate reasons only:**
1. **Specific regulation** on the data (gov, banking, health, regulated utility) → legal escalation before any destructive change.
2. **Explicit owner order** on a particular instance ("do not touch this host").
3. **Out of scope** — not under our administration.

List each exclusion with a classified reason + reference:

- **{{host/container}}** — Reason: {{regulation | owner order | out of scope}}. Detail: {{specific}}. Reference: {{reviewer veto msg-id / note / owner message}}.
- **{{host/container}}** — Reason: {{regulation | owner order | out of scope}}. Detail: {{specific}}.
- **N containers (list)** — Reason: {{owner order, e.g. "these are lab, install nothing"}}. List: {{a, b, c, ...}}.

**NOT legitimate reasons (anti-patterns to avoid):**
- "Our hardware but customer app" — irrelevant if we administer it.
- "Name looks external" — naming does not determine scope.
- "No explicit sign-off" — if administrative responsibility already exists by default, this is not an exclusion reason.

---

### Technical procedure

**Method:** {{e.g. run command inside each container/VM from the parent host, idempotently}}

**Hard rules of the procedure:**

- **DO NOT** {{thing not done — e.g. "connect directly before the key is in place"}}
- **DO NOT** {{thing not done — e.g. "modify the SSH daemon config or restart services"}}
- **DO NOT** {{thing not done — e.g. "rotate or generate new keys"}}
- **DO** {{thing done — e.g. "idempotent append to the target file"}}
- Permissions enforced: {{e.g. directory 700 + file 600}}
- Idempotent behavior: {{e.g. detect an existing line and skip it}}

---

### Controls applied

| Control | Implementation | When applied |
|---|---|---|
| **Idempotency** | {{e.g. check before append; reruns do not duplicate}} | pre-write |
| **Permissions** | {{e.g. directory/file modes enforced before and after}} | pre-write + post-write |
| **Pre-change backup** | {{e.g. pre-state captured and logged: line count + listing}} | pre-write |
| **Idempotency proven empirically** | {{e.g. pilot rerun N>=3 times, 1st INSERTED + rest ALREADY_PRESENT, visible to owner}} | during pilot |
| **Post validation** | {{e.g. independent check from the real origin confirms the change took}} | post-write |
| **Protective guard / hook** | {{e.g. a pre-execution guard blocked the automated attempt; executed via an explicit, documented owner-authorized bypass}} | pre-write (block) + during (bypass) |
| **Result log** | {{e.g. per-host result in a CSV file}} | during write |
| **Granular validation from origin** | {{e.g. validate from the real origin, not from the intermediate host}} | post-write |
| **Critical op vs validation distinction** | {{report BOTH metrics; N FAIL in validation does NOT imply automatic rollback — investigate the validator first}} | post-write |
| **Neutral language during execution** | {{use substitutable vocabulary when describing the change to reduce noise/anxiety}} | from step 1 to closeout |

> The **"When applied"** column distinguishes an effective control from a theoretical one. A control applied only "post" can be useless if the failure is in the write itself. Controls that matter most are usually applied pre-write.

---

### Rollback (individual + mass)

**Per individual host:**
```bash
{{exact rollback command for ONE host — e.g. remove the appended line from the target file}}
```

**Mass:** rollback script `{{path to mass rollback script}}` — generated in parallel with the apply script, NOT after the fact. It must be ready BEFORE the mass change runs.

**Estimated total rollback time:** {{N min}}

---

### Risks identified and mitigated

| Risk | Mitigation |
|---|---|
| {{e.g. bad permissions break the service on the target}} | {{e.g. explicit permission set BEFORE write}} |
| {{e.g. change lands on an out-of-scope host}} | {{e.g. hard exclusion list validated with owner}} |
| {{e.g. failure mid-batch}} | {{e.g. idempotent script — rerun does no harm}} |
| {{e.g. command fails in an exotic shell}} | {{e.g. pin the shell explicitly}} |
| {{e.g. ownership of a host is uncertain}} | {{e.g. case-by-case validation; only confirmed hosts enter scope}} |
| {{e.g. "our host = our container" comfortable assumption}} | {{e.g. reviewer flagged the anti-pattern before execution; granular classification applied}} |

---

### Closeout

**Status:** {{OPEN until... | CLOSED}}

**Closeout criteria (all must hold):**

- [ ] Mass script executed on every host in scope (N={{...}})
- [ ] Results captured in a log/CSV ({{path}})
- [ ] Granular validation OK per host (from the real origin, not from where it was executed)
- [ ] Surprise cases documented (unexpected category, script failure, host did not respond)
- [ ] Rollback tested on at least one sample host (optional, recommended)
- [ ] Marked closed with timestamp + results table (below)

**When all criteria hold**, close by adding the table:

```markdown
### Final results

| Host | Container/VM | Bucket | Result | Granular validation |
|---|---|---|---|---|
| {{host}} | {{id}} | in-scope | INSERTED | OK |
| {{host}} | {{id}} | in-scope | ALREADY_PRESENT | OK (idempotent, already present) |
| {{host}} | {{id}} | sister entity | FAILED (reason) | n/a |
| ... | ... | ... | ... | ... |

**Total:** N executed / X succeeded / Y unchanged (idempotent) / Z failed.
**Surprise cases:** {{none | list}}.
**Rollback executed:** {{no | yes, on N hosts, reason}}.

**Closed by:** {{executor role}}.
```

---

### Propagation after closeout

When closing the note, propagate lessons to:

- [ ] Reusable-lessons store, if the lesson is reusable.
- [ ] The relevant operational knowledge base.
- [ ] Notify the curator for audit.
- [ ] If the reviewer detected a meta-pattern, notify whoever maintains the templates/methods to refine them.
```

---

## Variables to substitute

| Variable | Example | Notes |
|---|---|---|
| `{{TYPE}}` | AUTH, NET, FW, CFG | Short category of the change |
| `{{NUM}}` | 005 | Incremental per TYPE |
| `{{REVIEW-MSG-ID}}` | reviewer verdict id | Id of the peer-review verdict |
| scope count | 26 | Total hosts in scope |
| exclusion count | varies | Total excluded |

---

## Difference vs a simple operational work-log

| Aspect | Operational work-log | This template |
|---|---|---|
| When written | After the work (post-hoc) | **Before the mass change** (defensive) |
| Status | "done" from the start | **"OPEN until..." with checklist** |
| Peer-review | Optional field | **Mandatory, with msg-id** |
| Rollback | Final command | **Mass + individual, BEFORE executing** |
| Exclusions | Implicit | **Listed, each with a reason** |
| Idempotency | Not tracked | **Mandatory + documented** |
| Validation | One final check | **Granular per host, from the real origin** |
| Closeout | Implicit | **Explicit checklist** |

---

## Common gotchas

These are not hypothetical — they surfaced in real operations and are worth folding into the "Technical procedure" or "Risks" sections as applicable. Some are environment-specific; keep them as generic slots and drop the ones that do not apply to your setup.

### G1 — Unquoted here-doc expands locally

Without quoting the marker, `$(...)` and `$VAR` expand in the origin shell, not on the remote target.

**Symptom:** a value computed in the wrong place (e.g. `$(wc -l file)` evaluated locally instead of on the target).

**Fix:** use a quoted marker: `<<'REMOTE'` (not `<<REMOTE`).

### G2 — Non-uniform service ports (generic slot)

If the fleet does not use a single, uniform port for the service you validate against, assuming one port breaks validation.

**Symptom:** N false FAILs in post-change validation, which can scare you into an unnecessary rollback.

**Fix:** after the change, run an independent sweep that probes every standard port in use; report OK when the service answers on any of them.

### G3 — Some platforms lack a native `timeout`

`timeout 10 cmd` does not exist by default on every platform (e.g. macOS).

**Fix:** use a portable wrapper, e.g. `perl -e 'alarm shift; exec @ARGV' 10 cmd args...`.

### G4 — A protective guard/hook blocks an authorized execution (generic slot)

If your tooling has a guard that blocks commands touching credentials/keys/passwords, it may block a legitimate, authorized run.

**Symptom:** the automated execution path fails on a guard match.

**Fix:** have the owner run it through an explicit, authorized bypass path, and **document in the note** that the guard blocked it and the bypass was explicit (never blind-automate the bypass).

### G5 — "Critical op OK" is not "validation OK"

Report both metrics separately. The validation step can have its own bug (G2 is an example). N FAIL in validation does NOT imply automatic rollback — investigate the validator first.

```
Critical op:     N/N OK  (100% INSERTED)
Post validation: M/N OK  ← if M<N, investigate the validator
```

### G6 — Loaded language triggers anxiety

Use neutral, substitutable vocabulary from the first command of the pilot, not just in the final report. The anxious moment arrives during execution.

### G7 — Shared volume between containers (a zombie + an active one)

If inspection reveals two stateful containers (database or similar) mounting the SAME named/bind volume:

- **STOP — investigate before operating.**
- The zombie (stopped but still an existing container object) may hold locks/handles on the volume.
- A recreate, network op, or restart of the active one can indirectly touch the zombie, forcing an unclean shutdown of it, leaving an inconsistent write-ahead log, leading to corruption.

**Quick pre-flight diagnostic:**
```bash
docker volume ls
docker ps -a --filter volume=<volume_name>  # includes zombies
```

**Mitigation:** remove a leftover zombie from a previous deployment before any other op; if it belongs to the active deployment, investigate the cause first; if it cannot be removed safely, stop the whole stack, remove zombies, and restart cleanly.

*(Generalized from an anonymized real incident.)*

### G8 — Compose recreate is not the same as an individual container op

Even though both manage containers, they are structurally different operations:

| Operation | Touches |
|---|---|
| Individual `run / stop / rm` | ONE specific container + its declared mounts/networks |
| `compose ... up -d --force-recreate <service>` | The whole stack: network composition, inter-service dependencies, volume locks, healthchecks, restart policies, other containers in the compose |

**Implication:** if a peer-review covered "individual stop/rm/run of container X", a compose recreate of the SAME container X needs a **NEW peer-review** (silent severity escalation). Compose can fail partway (e.g. a KeyError) but still execute partial steps (network recreate, dependency check, lock release) with side effects.

**Associated anti-pattern:** iterating variants of `run` after a compose failure **without diagnosing which partial steps already executed.**

### G9 — An anomaly seen at the start but not investigated (critical anti-pattern)

If, during pre-flight, you observe any of:

- A zombie/orphan container
- An unexpected mount
- A duplicate network
- A process listening on an undocumented port
- A recent `*.bak` / `*.swp` you do not recognize
- A lock file (`*.lock`, stale pid)

**STOP — investigate before operating.** Do NOT assume "it is inert so it does not matter," and do NOT proceed on "cleaning it up is not my job."

**Derived rule:** pre-flight is for **DETECT + INVESTIGATE**, not just for listing known gotchas. If an undocumented anomaly emerges, treat it as a potential unclassified gotcha: mark it (`POSSIBLE — anomaly X detected, investigate before next step`) and do NOT continue until it is resolved.

*(This passive-observation-without-investigation pattern detonated an anonymized real incident roughly an hour later.)*

---

## Code-review gotcha family (watch-list, not yet formalized)

The G1–G9 above are **infra/operations** gotchas. This distinct family covers **code review** (fixes to apps, scripts, logic).

### GC-1 (candidate) — Abort-in-loop on an edge element

**Anti-pattern:** code that iterates infrastructure resources (nodes, storages, hosts, VMs) does `return False` / `raise` / `break` on a **legitimately** empty/different element, aborting processing of everything else.

**Detection criterion:** can the rest of the collection be processed if I skip this element? **Yes → `continue`** (skip). **No → legitimate abort.**

**Why it matters:** in one observed case the same defect appeared at 4+ points in a single codebase, and the residual bug made a dashboard report a FALSE metric (artefactual SLA), which nearly triggered unnecessary operational work on bad data. A code anti-pattern produced a wrong business metric that almost set off the wrong operation.

**Code pre-flight:** when a change touches code that iterates infra resources, declare in the Gotchas table: *"are abort-in-loop points reviewed? continue-vs-abort criterion applied to each?"* Plus a proactive sweep: `grep -n "return False\|raise\|break" <file>` over resource-iteration loops.

---

*Template harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
