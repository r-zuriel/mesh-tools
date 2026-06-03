# Template — Architecture Decision Record (ADR)

Capture **one architectural decision** along with its context, the options considered, and why the chosen one won. Different from a work-log: a work-log records "what we did", an ADR records "why we decided this instead of the alternative".

## When to use

Use an ADR whenever you make a decision that will shape how something is built or operated in the future — and where a reader six months from now would otherwise wonder "why was it done this way?". Skip it for reversible, low-impact choices. Estimated time to fill in: 15-30 minutes.

---

## Template

```markdown
---
date: {{YYYY-MM-DD}}
slug: {{short-kebab-case}}
status: proposed | accepted | superseded by ADR-NNN | deprecated
deciders: {{you | you + reviewer | you + team}}
revisit-when: {{condition that would trigger a revisit}}
---

# ADR-{{NNN}} — {{Short title of the decision}}

## Context

{{What situation motivates this decision. What forces are at play. What are we trying to achieve.}}

Relevant constraints:
- {{Constraint 1}}
- {{Constraint 2}}

## Options considered

### Option A — {{name}}
- **Pros**: {{...}}
- **Cons**: {{...}}
- **Cost**: {{time / money / complexity}}

### Option B — {{name}}
- **Pros**: {{...}}
- **Cons**: {{...}}
- **Cost**: {{...}}

### Option C — {{name}}
(or more if applicable)

## Decision

**We choose**: {{option + why}}.

**Deciding criterion**: {{which factor weighed most in the end}}.

**Accepted trade-off**: {{what good thing from the other options we give up}}.

## Expected consequences

### Positive
- {{...}}
- {{...}}

### Negative / accepted
- {{...}}
- {{...}}

### Risks to watch
- {{...}}

## Implementation

{{Concrete steps that follow from this decision. Migration plan if applicable.}}

## Revisit when

{{Conditions that would make us reconsider this decision. Without this, the decision is treated as "forever", which is rarely true.}}

## See also

- {{Work-logs that apply this decision}}
- {{Related notes / lessons}}
- {{Other ADRs that depend on this one}}
```

---

## Rules

1. **One decision per ADR.** If your decision has three components, that is three ADRs (which may reference each other).
2. **Real options, not straw men.** If you only seriously consider one "viable" option, it is not an ADR — it is a justification. List at least two honest alternatives.
3. **Revisit-when is mandatory.** Without it, the decision never gets revisited and hardens into dogma.
4. **Living status.** When a decision is superseded, do NOT delete the ADR — change `status: superseded by ADR-NNN` and create the new one.

## Example topics

These are illustrative of the kinds of decisions worth an ADR:

- "Bundled standalone binary vs. system-installed runtime for a scheduled job"
- "Federated multi-repository knowledge base vs. a single monolithic store"
- "File-based message bus vs. another inter-process communication mechanism"
- "Catalog reusable methods once vs. duplicating them per module"
- "Job frequency of 30 minutes vs. 5 minutes for a polling task"

## See also

- Work-log template (a work-log can cite an ADR as its rationale)
- Peer-review template (a proposal to a reviewer is stronger when it cites an existing ADR)
- RACI / DACI (a decision-oriented variant for assigning ownership)

---
*Template harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
