# Template — Business ADR

A business-domain variant of the technical Architecture Decision Record (ADR), adapted for **strategic, commercial, and financial** decisions. Same skeleton as a technical ADR (context → options → decision → criterion → consequences → revisit), applied to a different domain.

## When to use

- Strategic decisions: entering a market, accepting or declining a category of client, forming a partnership.
- Commercial decisions: pricing policy, discounts, billing model.
- Financial decisions: equipment investment, hiring, recurring spend (SaaS, tooling).
- Brand or product decisions: brand stack, identity, positioning.
- Any decision with a non-obvious tradeoff and consequences lasting more than a month.

### When not to use

- Routine operations with no tradeoff (paying a recurring invoice that was already decided).
- Trivial decisions that are cheap to reverse.
- Purely technical decisions — use the standard technical ADR template instead.

## Template

```markdown
---
adr_id: ADR-BIZ-{{NNN}}
date: {{YYYY-MM-DD}}
status: {{Proposed | Accepted | Rejected | Superseded}}
deciders: {{the technical lead + the finance lead — both if strategic}}
affects: {{which area of the business — commercial / finance / brand / ops}}
revisit: {{YYYY-MM-DD}}
---

# ADR-BIZ-{{NNN}} — {{Decision title}}

## Context

{{The business situation forcing the decision. What changed, what pressure
exists, what opportunity or threat. Include numbers where available: costs,
expected revenue, deadlines.}}

## Options considered

### A — {{option}}
**Cost/investment:** {{$$ or effort}}
**Pros:** {{...}}
**Cons:** {{...}}
**Risk:** {{financial / reputational / legal}}

### B — {{option}}
{{...}}

### C — {{option}}
{{...}}

> If there are two or more viable options AND the choice commits more than
> two weeks of effort, consider a structured multi-voice debate before
> finalizing.

## Decision

**Option {{X}}.**

## Deciding criterion

{{The single factor that tipped the balance. Not "it's better overall" — the
concrete reason: ROI, legal risk, client relationship, capacity, cash flow.}}

## Expected consequences

### Positive
- {{...}}

### Negative / accepted risks
- {{...}}

### Impact on entity separation
- {{Does this decision touch resources or contacts that could blur the line
  between your personal, your own company, and your employer concerns? Keep
  those three spheres distinct: shared tools, accounts, contacts, or data
  must not cross boundaries. Note any crossover risk and how it is mitigated.}}

## Revisit when

**{{YYYY-MM-DD}}** or when {{trigger: market shifts, client change, cost
change, new regulation}}.

## See also

- {{related quote or estimate, if any}}
- {{client proposal derived from this decision, if any}}
```

## Difference vs a technical ADR

| Aspect | Technical ADR | Business ADR |
|---|---|---|
| Domain | architecture / infra / code | commercial / financial / strategic |
| Deciders | engineering roles | the technical lead + the finance lead |
| Typical criterion | reversibility, blast radius, technical debt | ROI, legal/financial risk, client relationship |
| Numbering | ADR-NNN | ADR-BIZ-NNN |
| Extra section | — | "Impact on entity separation" |

## Worked example (synthetic)

**ADR-BIZ-001 — Migrating the company website from a hosted design tool to a developer platform**

A small services company runs its marketing site on a drag-and-drop hosted design tool. The team considers moving to a developer-oriented hosting platform for lower cost and more control. The decision is captured as a Business ADR: context (why the move is being considered), options (stay on the current tool vs. two candidate platforms, checking each one's commercial terms of service), deciding criterion (cost plus control plus commercial-use licensing), and a revisit date once traffic or pricing changes.

---
*Template harvested from real operations at a mid-sized MSP, anonymized for public distribution. Feedback welcome via Issues.*
