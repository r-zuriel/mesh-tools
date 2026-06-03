# Peer-review severity classifier

A fast triage that decides whether an operation deserves a formal peer-review (a second pair of eyes before you execute) or whether it can proceed directly with the tool's own minimal safety net.

**Premise:** peer-review costs reviewer time. Demanding it for *every* operation is noise that trains people to ignore it. Reserving it for operations with a genuinely complex destructive surface focuses the reviewer where it matters.

The classifier sorts work into two categories:

- **Cat 1 — do not escalate.** Proceed directly with a minimal safety net.
- **Cat 2 — escalate.** Compose a structured proposal and get a second opinion before executing.

---

## When to use

Run this 1-2 minute check **before** any non-trivial operational change: deploys, migrations, production fixes, credential changes, destructive commands, or anything touching shared/critical infrastructure. The goal is to answer one question: *does this need a reviewer, or just a safety net?*

### The two-question test

```
1. Does the operation have a SINGLE known destructive path, or several?
2. Is the TOOL'S STANDARD ROLLBACK enough, or does recovery need external coordination?
```

| Case | Destructive path | Standard rollback | Severity |
|---|---|---|---|
| One path + standard rollback | single | yes | **Cat 1 — do not escalate** |
| Multiple paths | several | * | **Cat 2 — escalate** |
| Non-standard rollback | * | needs external coordination / manual snapshot | **Cat 2 — escalate** |
| Any case involving regulated data | * | * | **Cat 2 (mandatory)** + legal escalation |

### Category 1 — do not escalate (simple ops)

**Criterion:** single known destructive path, and the tool's standard rollback is sufficient.

Canonical examples:
- Extending a logical volume onto a blank disk (a metadata backup covers it).
- Adding a permission to a config file under version control (a checkout reverts it).
- Opening a firewall port (the inverse command closes it).
- Resetting a non-critical user's password where the new secret is already stored in the vault.
- Adding a DNS record (zonefile commit with backup).
- Installing a simple package (no kernel, no critical config).

Cat 1 flow:

```
1. Confirm the single destructive path (test above)
2. Apply the MINIMAL standard safety net (metadata backup / stash / dump / .bak)
3. Execute in one pass
4. Report the result
5. Document if the op produced a reusable lesson
```

No reviewer is invoked. No intermediate-checkpoint procedure is used.

### Category 2 — escalate (complex ops)

**Criterion:** multiple destructive paths, OR non-standard rollback, OR external coordination required, OR regulated data involved.

Canonical examples:
- Container-to-VM migration on a virtualization host.
- Rotating a TLS certificate that requires renaming dependent services.
- `DROP COLUMN` on a production database.
- Destroying a container or VM.
- A deploy with planned downtime.
- A production database `UPDATE` with a complex `WHERE` clause.
- A container image build + recreate against a live production app.
- Bulk credential rollout across many hosts.
- Changes that cross sensitive dimensions (regulated, customer-owned, shared infra).

Cat 2 flow:

```
1. Compose a structured proposal (context + premise + plan + rollback + risks + verification)
2. Send it to a reviewer for a second opinion
3. Wait for the verdict (APPROVE / APPROVE-WITH-MITIGATIONS / REJECT / NEED-INFO)
4. Apply ALL mitigations before executing
5. Execute with a staged rollout if many hosts, or step-by-step if destructive on one host
6. Acknowledge back to the reviewer at close
```

### Quick decision table (canonical)

| Type of op | Cat | Reason |
|---|---|---|
| Logical-volume extend / add disk | 1 | metadata backup covers it, single path |
| Add a non-privileged user | 1 | user deletion reverts it |
| Open/close a firewall port | 1 | inverse command covers it |
| Install a non-critical package | 1 | package removal covers it |
| Edit a config / dotfile under VCS | 1 | git/backup covers it |
| Reset a non-critical user's password | 1 | new secret already in vault, non-destructive |
| DB `UPDATE` with a specific `WHERE` | 2 | rollback needs a prior dump; path not unique (what if `WHERE` bites more rows?) |
| Container image build + recreate in prod | 2 | the previous image must be saved first |
| Credential rollout across many hosts | 2 | multiple hosts, coordination, bulk rollback |
| Rotate a TLS cert with service renames | 2 | dependent services may fall, rollback non-trivial |
| Container-to-VM migration | 2 | snapshot + maintenance window + coordination |
| `DROP COLUMN` / `DROP TABLE` | 2 (mandatory) | irreversible without an explicit backup |
| Destroy a container / VM | 2 (mandatory) | irreversible |
| Any op on regulated data | 2 (mandatory) + legal escalation | regulatory exception |
| Any op the owner explicitly said "do not touch" | out of scope | owner-set exclusion |

---

## When NOT to use

This classifier is overhead. Skip the reviewer (Cat 1) — or skip the check entirely — when:

- The operation is routine and self-reversing (a package update, a single file-permission change). Escalating these is the most common anti-pattern.
- The owner overrides mid-flow. If the person with contractual/urgency context says *"don't overcomplicate it,"* *"just do X,"* or *"only that"* — treat the op as Cat 1 even if you had initially classified it as Cat 2. Their override is an authoritative signal, not negligence.
  - **Exception to the override:** if the op is genuinely irreversible (`DROP TABLE`, `rm -rf` on system config, destroying a container with no backup, rotating a master key without the old one on hand), confirm the override explicitly once before executing: *"OK, no peer-review. Confirming I'm about to run X, which is irreversible. Proceed?"* — then wait for one more confirmation.

Anti-patterns to avoid:

- Escalating every routine update or file-permission change.
- Processing a Cat 2 op without review *because you're in a hurry*.
- Ignoring an owner's override *because the methodology says always escalate*.
- Confusing **the technical complexity of a command** with its **destructive surface**. A complex script with a bounded, idempotent effect is Cat 1; a one-line `DROP TABLE` is Cat 2.

---

## Mapping to harness tools

Two model-harness features map directly onto the two categories.

### Plan mode

Plan mode makes the agent plan *before* executing, present the plan, wait for approval, then act — it blocks edits/writes/commands with effects while leaving read and exploration open.

| Category | Plan mode? | How |
|---|---|---|
| Cat 1 trivial / standard | No (ceremonial) | — |
| Cat 2 | On-demand | enable per-session, or set as the default for a sensitive project |
| Cat 2 extreme (prod down, regulated, irreversible) | Mandatory | same, plus explicit approval of the plan |

Why it helps: in an anonymized real incident, blind iteration against a live database (a recreate-and-retry loop) corrupted a write-ahead log. With plan mode active that loop is structurally impossible — the agent cannot recreate the service without first presenting a plan and waiting for approval.

### Effort / depth control

| Category | Suggested effort | Reason |
|---|---|---|
| Cat 1 trivial | low | single command, obvious rollback |
| Cat 1 standard | medium | reasonable default |
| Cat 2 | high | multiple paths + impact warrant more depth |
| Cat 2 extreme | maximum | maximum caution |

Tradeoff: higher effort costs more tokens. For repetitive Cat 1 ops, low/medium saves cost. For Cat 2 and incidents, the depth is worth it. The same logic applies to "fast" modes — fine for research and low-risk Cat 1 work, off for Cat 2, incidents, and any op where the cost of an error far exceeds the cost of the model.

---

## Example

A synthetic walk-through of both directions.

**Op A — extend a near-full logical volume onto a fresh, unused disk.** Single destructive path; the tool's metadata backup fully covers rollback. Classified **Cat 1**. The operator takes the metadata backup, runs the extend in one pass, reports the result. No reviewer needed. (If the requester also says *"just do the volume, nothing else,"* that override only reinforces Cat 1.)

**Op B — fix a bug that requires a production database `UPDATE` plus a container image rebuild against the live app.** Two destructive surfaces (the `UPDATE` could bite more rows than intended; the recreate could ship a broken image), and rollback needs a prior dump and a saved previous image. Classified **Cat 2**. The operator composes a proposal (context, plan, rollback, risks, verification) and sends it to a reviewer. The reviewer confirms Cat 2 and returns mitigations (take the dump first, save the current image, scope the `WHERE` against a count query). Only after applying every mitigation does the operator execute, step by step, then acknowledges back at close.

The classifier earns its keep in *both* directions: it tells you what to escalate and, just as importantly, what not to.

---
*Method harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
