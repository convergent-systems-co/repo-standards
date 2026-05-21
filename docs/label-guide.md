# Label Guide

This document explains when to apply each label in the convergent-systems-co
standard. Source of truth: `labels.yml`. Cleanup rules: `label-aliases.yml`.

## Axes

Labels are grouped into five orthogonal axes plus two community flags.
Apply 1–2 labels from each axis as relevant.

### kind/ — what the issue IS (pick exactly one)

| Label | When to use |
|---|---|
| `kind/bug` | Something is broken. A repro is expected. |
| `kind/feature` | Net-new capability not present today. |
| `kind/enhancement` | Improvement to an existing capability. |
| `kind/docs` | Documentation only. |
| `kind/refactor` | Behavior-preserving change. |
| `kind/chore` | Build, CI, tooling, housekeeping. No user-visible change. |
| `kind/security` | Vulnerability or hardening. Treat as priority/critical until triaged. |
| `kind/rfc` | Design proposal or open discussion. |

### area/ — which surface (extensible per-repo)

The core areas in `labels.yml` are `api`, `cli`, `core`, `infra`, `ci`, `docs`,
`release`. Repos may add their own `area/*` labels via PR to their own repo,
but the cleanup pipeline will leave those alone if they are not in `labels.yml`
and not in `label-aliases.yml` (they fall into the "unmapped" report category
for human decision).

### priority/

| Label | Definition |
|---|---|
| `priority/critical` | Drop everything. Production down, data loss, active CVE. |
| `priority/high` | Current iteration. |
| `priority/medium` | Next iteration. Default. |
| `priority/low` | Backlog. |

### status/

Only three status labels are part of the standard. In-flight states
(in-progress, ready) live in Projects v2, not as labels.

| Label | Meaning |
|---|---|
| `status/triage` | Awaiting triage. Auto-applied on open by `triage.yml`. |
| `status/needs-info` | Author input required. Triage agent applies when it cannot infer required fields. |
| `status/blocked` | External dependency. Use sparingly; name the blocker in a comment. |

### resolution/ — close reason

Applied at close time for analytics. Mutually exclusive.

### Community

`good-first-issue` and `help-wanted` may apply at any time alongside the
above. Use them sparingly so they remain a real signal.

## Common combinations

A typical bug: `kind/bug` + `area/<surface>` + `priority/<level>` + (when
closed) `resolution/completed`.

A typical feature: `kind/feature` + `area/<surface>` + `priority/<level>`.

A typical proposal: `kind/rfc` + `area/<surface>`. Priority is optional for
RFCs.

## What NOT to do

- Don't combine multiple `kind/*` labels.
- Don't add `priority/*` to an RFC unless it has been accepted.
- Don't use `resolution/*` while the issue is open.
- Don't replicate Projects v2 board state (iteration, effort) as labels.
