# Pre-flight, flags, and gotcha closeout

A lightweight discipline for making the *implicit knowledge* you apply during a
non-trivial operation **visible** to the people watching — and to your future
self when you harvest lessons later.

Most teams accumulate "gotchas": hard-won rules like *"always check storage
status before this kind of update because it has silently vanished before"* or
*"wrap remote commands in a timeout on this platform"*. The problem is that
experienced operators apply these rules silently. The work gets done correctly,
but nobody observing can tell *which* disciplines were exercised, and recovering
that information after the fact means re-reading the entire execution log.

This method turns implicit knowledge ("I apply it because I know it exists")
into explicit knowledge ("I declare that it applies, I flag it when I cross it,
I summarize it when I close"). Three phases: a **pre-flight** declaration before
you start, **inline flags** during execution, and a **closeout summary** when
you finish.

## When to use

- A non-trivial operation that warrants review before execution.
- An operation touching a subsystem that already has a body of documented
  lessons or known failure modes.
- An operation applying a procedure that has its own documented sub-disciplines.
- An operation a colleague will read in real time — visibility matters.
- An operation you will write up afterward in a work log — the summary feeds
  that write-up directly.

## When NOT to use

- Trivial, low-risk operations that don't warrant review at all.
- A single informational or read-only exploration command (`ls`, `cat`, `ps`).
- Fully automated, non-interactive runs with no human observer.

## The three phases

### Phase 1 — Pre-flight (before you execute)

Before touching anything, **list the gotchas and disciplines that apply to this
specific case**.

There are three legitimate sources of gotchas, and all three are valid:

| Source | Where it comes from | Example |
|---|---|---|
| **Memory-derived** | Your subsystem lessons / feedback notes | "log shipper rejects the cert if the IP is missing from the SAN" |
| **Tool/rule-derived** | The standing rules you always follow | "anchored heredocs for multi-line remote exec", "timeout wrapper on remote calls" |
| **Ad-hoc** | Specific to *this* fix | "this cluster's HA layer breaks sync when a node is empty", discovered while validating the current case |

A useful heuristic: distinguish **substantive** from **ceremonial** entries.

- Substantive: a mitigation specific to the case — *"verify storage status
  before the update because storage X has historically disappeared in cluster
  Y."*
- Ceremonial: a generic copy-pasted mitigation — *"apply discipline X during
  execution"* — with no reference to the concrete case.

If your table lists only generic standing-rule gotchas with nothing specific to
the case, that is a signal of a ceremonial pre-flight. At least one
memory-derived or ad-hoc gotcha carries more value than rules quoted without
context.

**Canonical output format:**

```markdown
## Pre-flight — gotchas that apply to this case

| Gotcha / Discipline | Applies | Reason / planned mitigation |
|---|:---:|---|
| Anchored heredoc | YES | multi-line remote exec → use `<<'REMOTE'` |
| Non-uniform SSH ports | NO  | a single known port in this case |
| No default timeout on platform | YES | running from a workstation → use a timeout wrapper |
| Guard hook may block | MAYBE | touches authorized_keys → will request an override if it blocks |
| Critical op vs. post-validation | YES | report the two metrics separately |
| Neutral language while editing | YES | touches credentials → substitutable vocabulary |
| Idempotency proven by re-run | YES | pilot re-run N=3 before the bulk apply |
| Mid-flight self-correction | MAYBE | if empirical validation invalidates an assumption, refine before the verdict |
| Stop-check uncovers bugs | YES | checkpoint between phases scoped for discovery |
| Operational-ownership confirmed | VERIFY | scope includes client resources → confirm ownership |
```

**Hard rules for Phase 1:**

1. Never omit the section. If the operation qualifies as a trigger, the section
   is mandatory.
2. Each row carries exactly one of three values: `YES` / `NO` / `MAYBE`. Do not
   use "perhaps" / "it depends" / "we'll see".
3. If it applies (`YES`), the reason must state a **concrete planned
   mitigation** — what you will do, not merely "be careful".
4. If it does not apply (`NO`), the reason must be **empirically dismissible**,
   not "I think not".
5. If `MAYBE`, declare the **activation trigger** ("if X happens, I activate Y").
6. Include at least one memory-derived or ad-hoc gotcha, not only
   standing-rule ones — this is the anti-ceremonial guard.

#### Optional sub-table — anti-false-positive notes for the reviewer

The pre-flight table can be **bidirectional**. There are two axes:

- **Axis 1 — operational gotchas**: disciplines *you*, the executor, apply.
- **Axis 2 — anti-false-positive notes for the reviewer**: disciplines that
  warn the reviewer about known over-corrections, so they don't flag something
  that is actually fine.

```markdown
## Anti-false-positive notes for the reviewer (Axis 2)

| Known reviewer pattern | Applies here | Anti-false-positive citation |
|---|:---:|---|
| over-correction toward "case-by-case approval required" | NO restriction | default = access per the documented ownership model (cite the source) |
| aggressive premature enumeration | WATCH | if I propose a 4-value enum from a single empirical case, call it out |
```

The benefit is preventing an over-corrected verdict *before* the review rather
than after. Apply Axis 2 only when the case resembles one where the reviewer has
previously produced a false positive, or where a recently harvested decision may
not yet be internalized.

Do **not** use Axis 2 to "sell" the reviewer a predetermined conclusion. If you
declare *"pattern X does not apply because opinion Y"* with no citation to a
written source, that is ceremonial. The external citation — a documented lesson,
a recorded decision, written feedback — is what gives the note legitimacy, not
your opinion.

### Phase 2 — Inline flags (during execution)

When you cross a known gotcha during execution, **flag it visibly** in your
output, immediately before the relevant command.

```
>>> APPLYING anchored-heredoc: multi-line remote exec with <<'REMOTE'

ssh user@<host> "exec-into <container> -- bash <<'REMOTE'
  echo \$count
REMOTE"

>>> APPLYING timeout-wrapper: bounding the remote call

timeout 30 ssh user@<host> ...
```

**Hard rules for Phase 2:**

1. The flag goes *before* the command it applies to, not after.
2. Short identifier plus a one-line description.
3. Do not over-flag — only gotchas declared `YES` or activated from `MAYBE` in
   the pre-flight.
4. If a **new** gotcha emerges during execution (not in the pre-flight), flag it
   inline and make a note for the closeout.

### Phase 3 — Closeout summary

When you close the operation, **summarize** what was applied, what was avoided,
and what emerged.

```markdown
## Gotcha summary — operation closeout

### Disciplines applied (declared in pre-flight + executed)
- anchored heredoc — 4 instances in the bulk script
- timeout wrapper — on every remote call
- critical op vs. validation — reported 26/26 written vs. 15/26 reachable (false fails investigated)
- idempotency by re-run — pilot ran 5 times, WRITTEN → ALREADY_PRESENT ×4

### Disciplines avoided (declared MAYBE, not activated)
- guard hook — did not block this time
- mid-flight self-correction — the initial proposal passed validation unchanged

### Disciplines not applicable (declared NO in pre-flight)
- non-uniform ports — a single host was involved

### NEW gotchas that emerged
- (if any) cluster HA layer with empty nodes silently fails sync → harvest as a new rule

### Application metric
- Pre-flight coverage: N declared / M executed = X% precision
- Elapsed time from Phase 1 to Phase 3: Y min
```

**Hard rules for Phase 3:**

1. The summary goes in the final work log and in the acknowledgement back to the
   reviewer.
2. New gotchas that emerged are direct input for whoever curates the team's
   knowledge base (to harvest into the lessons store) and for the reviewer (to
   judge whether it is a harvestable pattern or an edge case).
3. If coverage is below ~80%, investigate why. Poorly predicted gotchas signal
   that the subsystem's documentation is incomplete or that the applicability
   classifier is failing.

## Success metrics for the method itself

- **Pre-flight coverage**: percentage of gotchas that *did* activate and were
  declared in pre-flight. Target ≥80%.
- **False positives**: gotchas declared `YES` that never activated. Target ≤20%.
- **Post-closeout emergences**: new gotchas surfaced in the summary that were not
  yet documented — a sign the gotcha base is growing. Target around 1 per 5
  operations.
- **Observer visibility**: a colleague can read the pre-flight, the flags, and
  the summary and understand which disciplines were applied without asking.
  Qualitative.

## Expected benefits

1. **Visibility** — observers see which disciplines are exercised without having
   to infer them from the log.
2. **Easier harvesting** — the summary is direct input for documentation and
   review on the next case.
3. **Gotchas don't atrophy** — actively declaring them keeps them fresh in the
   system.
4. **Faster onboarding** — a new team member can read a pre-flight and learn
   which disciplines a given operation demands.
5. **Cross-validation** — if a reviewer sees a verdict with no pre-flight, an
   omitted gotcha becomes visible, improving proposal quality.

## Anti-patterns to avoid

- **Ceremonial pre-flight** — copy-pasting a generic table without thinking
  about what applies to the real case.
- **Excessive flags** — marking every command as a gotcha degrades the signal.
- **Summary without metrics** — "we applied gotchas X, Y, Z" with no numbers or
  evidence.
- **Pre-flight and execution out of sync** — declaring a gotcha `YES` but not
  applying it during execution. That signals non-compliance, not method.
- **Skipping the method "because I'm in a hurry"** — if the operation warrants
  review, the pre-flight is not optional.

## Example (synthetic)

A bulk credential-loading operation across many containers, modeled on an
anonymized real incident.

```markdown
## Pre-flight — bulk credential load

| Gotcha / Discipline | Applies | Mitigation |
|---|:---:|---|
| Anchored heredoc | YES | multi-line remote exec with `<<'REMOTE'` |
| Non-uniform SSH ports | YES | post-load reachability sweep across the known port set |
| No default timeout on platform | YES | timeout wrapper on every remote call |
| Guard hook on authorized_keys | MAYBE | pre-exec guard may block → will request an override |
| Critical op vs. validation | YES | report writes and reachability checks separately |
| Neutral language | YES | touches credentials → "append a line", not loaded verbs |
| Destructive-op checklist | YES | documented rollback + idempotency + pre-change backup |
| Pilot in buckets | YES | classify the targets into buckets with confirmation |
| Operational-ownership confirmed | YES | ownership of all in-scope hosts confirmed |
```

```markdown
## Closeout

Applied: anchored heredoc, timeout wrapper, critical-vs-validation reporting,
neutral language, idempotency-by-re-run.
Activated from MAYBE: non-uniform ports — needed once inside the target after load.
NEW gotcha: hosts without a guest agent make IP discovery impossible without a
host-side bridge lookup → harvest into the lessons store.
```

## How it integrates with sibling methods

| Method | How the gotcha pre-flight integrates |
|---|---|
| Peer review (proposal + reviewer) | A new mandatory "## Declared gotchas" section in the proposal. If missing, the reviewer may request info or approve with an observation. |
| Staged pilot + bulk rollout | Add the pre-flight as an early step and the summary as a closing step, between the review and the pilot. |
| Cluster-wide expedition triage | During cluster validation, flag the gotchas that apply to hosts in scope. |
| Roped-team change (spec + impact + close) | Pre-flight in the spec/impact phase; summary in the close/lesson phase. |
| Destructive-op checklist | Complementary — the checklist validates the change dimensions; the pre-flight makes visible which gotchas apply. |

## Origin

The method was harvested after a methodology audit where an observer noted that
the team applied many documented disciplines but never *declared* them — no
gotchas, no flags, no checkpoints visible in the output. All the documented
knowledge lived as consultable post-hoc lessons, but it was applied implicitly.
In the pilot incident, an operator silently applied several disciplines while
fixing an application bug, and the observer had to deduce them from the log.

Without explicit visibility, gotchas atrophy: they stay documented but are never
actively exercised, and observers lose the ability to validate in real time
which disciplines are in play.

---
*Method harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
