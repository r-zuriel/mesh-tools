# Mesh peer-review — structured proposal + reviewer

Before executing non-trivial operational work, an operator composes a **structured
proposal** and sends it to a separate **reviewer** identity for adversarial review.
The reviewer replies with a verdict — approved / rejected / needs-info — backed by
cited reasons. The operator then iterates or executes accordingly.

This method assumes two cooperating roles connected by a message bus (a "mesh"):

- **builder / operator** — the identity about to do the work.
- **reviewer** — a separate identity whose only job is to challenge the plan.

The roles must be distinct. A builder reviewing its own work defeats the purpose;
the value comes from a genuine second opinion applied before anything irreversible
happens.

## When to use

- You are about to apply, change, deploy, migrate, restart, or reconfigure something
  on a live system.
- You are in the middle of such work and want a review while it is still reversible.
- You just finished and want a post-hoc review against the real outcome.
- The plan contains a destructive command (pairs well with a pre-flight safety
  checklist).
- A change goes to production without a clear maintenance window.
- A migration, deploy, or cutover.
- A credential or access change.
- A pattern is being carried over from another subsystem and you are not sure it
  applies cleanly (a common source of mistakes).

## The proposal structure

The proposal is a single markdown document with fixed sections. The order matters:
purpose comes first, because without it the reviewer cannot weigh the cost of *not*
acting.

```markdown
## Purpose / why now        (required, always first)
<intent + urgency>

## Verified premise
<current system state confirmed, not assumed>

## Declared gotchas
| Gotcha / discipline | Applies | Mitigation |
|---|:---:|---|
| ... | yes/no/partial | ... |

## Plan (numbered, phased if needed)
1. ...
2. ...

## Rollback
<exact command + estimated time + what is lost>

## Risks R1...Rn
<each identified risk + its mitigation>

## Post-change verification
<what to measure or observe to confirm success>
```

Rules that the reviewer enforces:

1. **Purpose before plan.** If you cannot state what you are trying to achieve, the
   reviewer cannot judge whether the change is worth its risk. Omitting purpose is the
   single most common reason a proposal is bounced back as needs-info.
2. **Verified premise, not assumed.** If you claim "the runtime is installed on the
   target," confirm it before sending. Unverified assumptions that later prove false
   are a recurring failure mode.
3. **Rollback is mandatory.** Without a rollback path, the reviewer rejects regardless
   of how good the rest looks.
4. **Pre-checks executed.** If a proposal is destructive and the operator admits the
   pre-checks were not run, the reviewer rejects.
5. **Declare gotchas.** If a pre-flight check was done but not declared in the
   proposal, the reviewer has no visibility into which disciplines were applied and may
   ask for info.

## Flow

```
[builder]
> I'm about to do X
  -> compose proposal with the structure above
  -> send to reviewer over the bus, attaching the proposal
  -> status: waiting-for-reviewer

[reviewer]
> check inbox
  -> read proposal, read prior lessons on the topic
  -> apply the review checklist
  -> verdict: approved | rejected | needs-info
  -> reply to the builder, referencing the original message
  -> log the verdict for future reference

[builder]
> check inbox
  -> read verdict
  -> execute (if approved) / iterate (if needs-info) / drop (if rejected)
```

### Variants

- **Round 1 -> Round 2.** If the reviewer asks for info, the builder resolves the open
  points and sends a second round.
- **Post-hoc log.** When work was executed with unanticipated discoveries, the builder
  sends a post-hoc note to the reviewer listing the bugs found, so they are logged as
  learning.
- **Mid-verdict self-correction.** If the builder discovers an error in its own
  proposal *after* sending but *before* the verdict — typically because an empirical,
  read-only validation invalidated an initial assumption — it sends a refinement on the
  same proposal thread before the reviewer rules. The reviewer then judges the refined
  version, not the original.

#### Sub-discipline — legitimate mid-verdict self-correction

**When it applies:** the builder sent a proposal. Before the verdict, it ran a
read-only empirical check against the target and found that an initial assumption was
wrong, invalidating part of the plan.

**Correct action:** send a refinement on the same thread (subject `Re: <original> —
self-correction N`) before the reviewer rules. Document:

- Which assumption was invalidated, with concrete empirical evidence.
- What changes in the plan.
- What parts of the original plan still hold.

This is not a protocol violation. The reviewer values a refined proposal backed by
empirical verification more than an unverified initial one. Self-correcting mid-verdict
demonstrates discipline, not negligence.

**Anti-patterns to avoid:**

- Sending five or more refinements in a row — a sign the original proposal should not
  have been sent yet (insufficient up-front validation).
- Refining without new empirical evidence (that is an opinion debate, not a
  self-correction).
- Sending a refinement *after* the verdict and pretending it belongs to the original
  round (that is a new round, not a self-correction).
- Hiding the self-correction or mixing it into execution; it must be explicit on the
  thread.

**Derived rule:** if you find yourself refining three or more times before a verdict,
**stop and rewrite the proposal from scratch.** That many refinements means the
original premise was not mature.

## When NOT to use

- The current session is the reviewer (it does not review itself).
- Trivial work (typo, whitespace, comment, read-only query).
- The work is simple and well-scoped, with a single known destructive path and the
  tool's standard rollback — and forcing a full proposal would only add friction.
- The same proposal was already sent in this session.

## Example

A builder is about to update a metadata table that drives storage selection on a host.

The original proposal assumes: *rows that have a storage value are the live ones; empty
rows are legacy.* The plan would clear the empty rows.

Before the reviewer rules, the builder runs a read-only status command against the
target and finds the opposite: the empty rows are the live ones, and the rows with a
stored value point at obsolete, decommissioned storage.

The builder sends two refinements on the same thread:

- self-correction 1: invert the logic of the update.
- self-correction 2: confirm the obsolete storage entries and set them to null.

The reviewer judges the twice-refined version and approves it, noting it as a positive
pattern: the builder caught an error in its own fix before the verdict, validated it
empirically against real data rather than assuming, and refined before acting.

---
*Method harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
