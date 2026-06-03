# Methodology templates

Reusable working methods, harvested from real operations and anonymized for
public use. Each is a Markdown doc with **when to use / steps / when NOT to use /
example**. Adapt them to your own team and tooling.

These pair naturally with the [mesh](../mesh/) (peer review, document-on-close)
and the [visibility hooks](../hooks/), but stand alone as plain methodology.

## Methods

| Method | Use it for |
|---|---|
| [Cordada — roped-team operations](cordada-roped-operations.md) | the integrator: any non-trivial operation on live systems |
| [Staged mass rollout](staged-mass-rollout.md) | the same change across many hosts/files |
| [Pre-flight, flags & gotcha closeout](preflight-flags-gotchas.md) | making implicit gotchas explicit before/during/after a risky op |
| [Peer-review severity classifier](peer-review-severity-classifier.md) | deciding when a change needs a second opinion |
| [The 4 checks](four-checks-destructive-ops.md) | before any destructive command |
| [Mesh peer-review](mesh-peer-review.md) | structured proposal → reviewer verdict |
| [Document on close](document-on-close.md) | propagating lessons when work finishes |

## Templates

Copy-paste skeletons under [`templates/`](templates/):

| Template | For |
|---|---|
| [Mass-change work-log](templates/mass-change-worklog.md) | a defensive log opened *before* a bulk change |
| [Architecture Decision Record](templates/adr-technical.md) | technical decisions with trade-offs |
| [Business ADR](templates/adr-business.md) | strategic / commercial / financial decisions |
| [Build & frontend gotchas](templates/build-frontend-gotchas.md) | a pre-flight checklist for distributable code, CI, and frontend |

> Methods are descriptive, not prescriptive — take what fits, drop what does not.
