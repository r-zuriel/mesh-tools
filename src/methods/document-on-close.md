# Document on close

When a non-trivial piece of work is finished, the lesson it produced should be captured in more than one place — not just where the work happened. A fix logged only inside the subsystem it touched is invisible to the next person facing the same problem in a different context. This method makes propagation a step of "done," not an afterthought.

The core observation that motivated it: in practice, almost nobody writes documentation voluntarily. The operator finishes the task, moves on, and the knowledge evaporates. So documentation has to be triggered by completion itself, proactively, rather than waiting for a request that never comes.

## When to use

Trigger documentation whenever a non-trivial unit of work concludes:

- A bug is fixed, a feature shipped, a service deployed or installed.
- A configuration change, patch, migration, refactor, or integration lands.
- An incident is resolved, a CVE remediated, a build succeeds.

Concrete signals worth treating as triggers:

- A person signals completion: "done," "it works," "resolved," "merged," "deployed," "validated."
- A pull request closes.
- A long-running command finishes successfully (a build, a restore, a bulk sync, a migration).
- A sequence of edits and commands clearly wraps up one logical unit of work.

## Where to propagate

Aim for at least three destinations, chosen by the *kind* of lesson rather than where the work physically happened. The point is that the same fact should be discoverable from several angles.

1. **The subsystem's own documentation.** Whatever lives closest to the change: the README, changelog, runbook, or an incidents log for the component you touched. This is the local record — what changed and why.

2. **A portable knowledge base.** The generic, reusable form of the lesson, stripped of the specific environment. If the gotcha is really about how a Linux command or a protocol behaves, it belongs somewhere that future, unrelated work can find it — not buried in one project's history.

3. **A reusable memory.** A durable note keyed to the topic, holding the non-obvious facts you would otherwise rediscover the hard way. This is the layer that survives across sessions and contexts.

Depending on the lesson, two more destinations are worth considering:

- **A case study in the domain-specific knowledge base**, when the value is in how this particular environment behaved.
- **A guardrail or checklist update**, when the lesson is really a pattern to catch next time — for example, a destructive-operation checklist, or a review pattern an adversarial reviewer should flag in future proposals.

A simple completeness test: the lesson should be findable through at least three independent search paths. Search your knowledge bases for a unique keyword from the lesson; if it turns up in fewer than three places, propagation is incomplete.

A rough mapping by lesson type:

| Lesson type | Minimum destinations |
|---|---|
| Generic technical gotcha (a command, an OS behavior) | reusable memory · portable knowledge base note · subsystem doc |
| Anti-pattern in a proposal | reusable memory · reviewer's pattern log · review checklist |
| Destructive-operation pattern | reusable memory · reviewer's pattern log · destructive-ops checklist |
| Environment-specific lesson | reusable memory · subsystem case study · portable runbook |

## When NOT to use

- Trivial work: a typo, whitespace, a comment, a formatting pass. Logging these everywhere is just noise that dilutes the real lessons.
- Exploration that changed nothing: reading, diagnosis that did not lead to action.
- Work that is paused, not finished.

There is a real anti-pattern here: documenting the trivial. The cross-context propagation cost is only worth paying for lessons that will actually save future effort. Filter aggressively.

## Variants

- **Document mid-work.** On a very long task — many hours, many fixes — capture lessons partway through instead of waiting for the end, so a broken session does not lose the context.
- **Retroactive documentation.** A curator role can detect work that was executed without a record and write the documentation after the fact. This is the fallback for when operators lose the thread during intensive work: a separate pass audits for undocumented work and propagates it.

## Example

A synthetic case, drawn from an anonymized real incident.

An operator runs a filesystem-tuning command against a live host (`host-a`) during routine maintenance. The command has a destructive side effect that is not obvious from its name, and the host's data becomes unrecoverable in place. The incident is contained and the host restored from backup.

On close, the lesson propagates to at least three places:

1. **Subsystem doc / incidents log** for that host class — what happened on `<host>`, the exact command, the blast radius.
2. **Portable knowledge base** — a note on the command itself: the dangerous flag, why its name misleads, and the safe alternative. This is the form a future operator, in a completely different environment, can find.
3. **Reusable memory** — keyed to the topic so the next session starts already aware of the trap.

Because the lesson is also a *destructive-operation* pattern, it additionally updates a pre-execution checklist: confirm the effect of any tuning command on a live system before running it. Afterward, a keyword search for the command turns up matches in three independent locations — propagation verified.

---
*Method harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
