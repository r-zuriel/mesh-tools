# Example: a builder hands work to a reviewer

End-to-end walkthrough of the mesh bus with two identities. Everything below
is copy-paste runnable; all content is synthetic.

## Setup (once)

```bash
mesh-init.sh init
mesh-init.sh register builder "dev/build agent"
mesh-init.sh register reviewer "adversarial pre-release reviewer"
mesh-init.sh set-default builder
```

## 1. Builder requests a pre-release review

```bash
cat <<'EOF' | mesh-send.sh builder reviewer "Review request: api-gateway v1.2.0" --priority high
# Proposal: release api-gateway v1.2.0

## Context
Adds rate limiting to the public endpoints. 14 commits since v1.1.0.

## Declared risks
- New dependency (token bucket lib) — pinned, license MIT.
- Config default changes: burst=20 → burst=50.

## Verification done
- Unit + integration green locally and in CI.
- Load test: 2k req/s sustained, p99 < 80ms.

## Question
Anything blocking the tag?
EOF
```

Output is the path of the message file dropped in the reviewer's inbox.

## 2. Reviewer picks it up

```bash
mesh-check.sh reviewer
# Inbox for 'reviewer' — new messages:
#   20260115T093012-from-builder-a1b2c3d4  🟡  Review request: api-gateway v1.2.0

mesh-check.sh reviewer --show 20260115T093012-from-builder-a1b2c3d4
```

## 3. Reviewer replies with a verdict (threading via --reply-to)

```bash
cat <<'EOF' | mesh-send.sh reviewer builder "Re: api-gateway v1.2.0 — APPROVE with 1 fix" --reply-to 20260115T093012-from-builder-a1b2c3d4
VERDICT: APPROVE with 1 pre-tag fix.

The burst default change (20 → 50) is not in the changelog — a consumer
relying on the old default gets a silent behavior change. Document it as
a breaking-ish note, then tag.
EOF

mesh-check.sh reviewer --read 20260115T093012-from-builder-a1b2c3d4
```

## 4. Builder closes the loop

```bash
mesh-check.sh builder            # sees the verdict
# ...applies the fix, tags, and reports back with another --reply-to message
```

That's the whole pattern: structured proposal → adversarial verdict →
fix → close the loop. The [methods](../src/methods/mesh-peer-review.md)
describe when this is worth the round-trip and when it isn't.
