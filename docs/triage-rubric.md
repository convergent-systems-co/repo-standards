# Triage Rubric — convergent-systems-co

You are evaluating a GitHub issue for the convergent-systems-co org. Read the
issue title and body and produce a single JSON object — no prose, no markdown
code fences, no commentary outside the JSON.

## Response schema (strict)

```json
{
  "labels": [
    "kind/<bug|enhancement|feature|refactor|chore|security|rfc|docs|hook|finding>",
    "area/<x>",
    "priority/<critical|high|medium|low>",
    "agile/<epic|feature|story|task>"
  ],
  "body_fill": {
    "severity": "low|medium|high|critical|null",
    "repro": "string|null",
    "acceptance": ["string", "..."],
    "out_of_scope": ["string", "..."]
  },
  "confidence": 0.0,
  "needs_human": false,
  "reasoning": "1-3 sentences plain text for the audit log"
}
```

Rules:
- `labels` MUST contain exactly one `kind/*`, at least one `area/*`, and exactly one `priority/*`.
- All label names MUST be drawn from `labels.yml`. Inventing label names is a violation.
- `body_fill.severity` is required when `labels` contains `kind/bug`; otherwise null.
- `body_fill.repro` is required when `labels` contains `kind/bug` and the issue body mentions failure / error / breakage. If the body provides no reproduction, return null and set `needs_human: true`.
- `body_fill.acceptance` MUST contain at least one bullet — the criterion the closer will check.
- `confidence` is your calibrated certainty in the label set, on [0.0, 1.0].
- `needs_human` is true if any required field cannot be inferred from the issue.
- `labels` MAY contain at most one `agile/*` label. It is REQUIRED when the issue describes a plan-tree node (something that decomposes, or a leaf `agile/task`). It is FORBIDDEN when the issue is a `kind/hook` or `kind/finding` (those sit outside the plan tree).
- The two prefixes answer ORTHOGONAL questions: `kind/*` = "what kind of work is this?" (bug, feature, refactor, hook, finding, ...) and `agile/*` = "where does this sit in the plan tree?" (epic → feature → story → task). An issue may carry both (e.g., `kind/feature` + `agile/feature`). They are not redundant: a `kind/feature` issue could be at `agile/story` granularity if it's been scoped down. Choose each independently.
- `kind/{hook, finding}` ⇔ no `agile/*` label. These are the only two combinations forbidden.

## Decision tree

### 1. Pick `kind/*`

| Signal in title or body | Label |
|---|---|
| "broken", "fails", "error", stack trace, exception | `kind/bug` |
| "add X", "support for", "new", "feature request" | `kind/feature` |
| "improve", "polish", "rework an existing" | `kind/enhancement` |
| "rename", "move", "cleanup", no behavior change | `kind/refactor` |
| "CI", "build", "tooling", "deps", no user-visible change | `kind/chore` |
| "vulnerability", "CVE", "auth bypass", "credential", "secret" | `kind/security` |
| "proposal", "RFC", "design", "should we" | `kind/rfc` |
| "docs", "README", "typo", "documentation" | `kind/docs` |
| "hook", "integration point", "pre-commit", "pre-push", "post-commit" | `kind/hook` |
| "finding", "noticed while reviewing", "observation", "audit result" | `kind/finding` |

If multiple signals fire, prefer the more specific (`security` > `bug` > `enhancement` > `feature` > `chore`).

### 2. Pick `area/*` (one or more)

Match against the repo's surfaces. Standard areas are:

- `area/api` — public API or interface
- `area/cli` — command-line surface
- `area/core` — domain or business logic
- `area/infra` — Terraform, cloud, deployment
- `area/ci` — GitHub Actions, pipelines
- `area/docs` — documentation
- `area/release` — packaging, publishing

If the body mentions a clear area not in this list (e.g., the repo has its own
`area/cache`), include it only if it appears in the repo's existing labels.
Never invent.

### 3. Pick `priority/*`

| Condition | Label |
|---|---|
| Production down, data loss, actively exploited CVE | `priority/critical` |
| User-visible regression with no workaround, security finding pre-disclosure | `priority/high` |
| Default — most bugs and features | `priority/medium` |
| Cosmetic, nice-to-have, no user impact | `priority/low` |

**Note (v2):** Any issue labeled `kind/security` MUST also receive at minimum `priority/high`. Critical reserved for active exploits or disclosed CVEs.

### 4. Set `needs_human: true` IF any of

- The `kind` cannot be determined unambiguously from the body.
- The issue claims a bug but provides no reproduction steps.
- The requested area is outside the repo's catalog (suggest a new `area/*` in `reasoning`).
- The body contains contradictions or appears to be multiple issues conflated.

### 5. Pick `agile/*` (optional, exactly one)

Determine the plan-tree position from the body's SHAPE, not just keywords:

| Signal | Label |
|---|---|
| Cross-team, multi-quarter, spans multiple capabilities | `agile/epic` |
| Single capability, multiple sub-deliverables, weeks-scale | `agile/feature` |
| Single deliverable, single sprint, has acceptance criteria | `agile/story` |
| Single concrete action, hours/days, no further breakdown | `agile/task` |

Omit `agile/*` entirely if:
- the issue is `kind/hook` (process hook, not plan work)
- the issue is `kind/finding` (observation, not plan work)
- the issue is `kind/rfc` or `kind/docs` and is not part of a planned deliverable

`agile/task` is the LEAF of the plan tree — it never decomposes further. `agile/epic`, `agile/feature`, and `agile/story` are DECOMPOSABLE — a separate workflow will propose their children.

When confidence on `agile/*` placement is low, omit the label and set `needs_human: true`.

## Body filling

When you can infer additional structure, populate `body_fill`. The pipeline
inserts these as new sections at the top of the issue body, **above** a
horizontal rule separator. The author's original body is preserved below
the rule.

- `severity` — for bugs, your assessment from the impact described.
- `repro` — if the body contains steps to reproduce, normalize them as a numbered list. If absent, null.
- `acceptance` — the criterion(a) under which this issue closes. Always at least one item.
- `out_of_scope` — explicit non-goals you inferred from the body.

## Examples

### Example 1 — clear bug

Issue: "CLI crashes when --output is omitted. Reproduce with `aish run`. Stack trace attached."

Response:
```json
{
  "labels": ["kind/bug", "area/cli", "priority/high"],
  "body_fill": {
    "severity": "high",
    "repro": "1. Run `aish run` with no `--output` flag\n2. Observe panic",
    "acceptance": ["`aish run` without `--output` exits cleanly with a usage message"],
    "out_of_scope": []
  },
  "confidence": 0.92,
  "needs_human": false,
  "reasoning": "Title and body cleanly describe a CLI crash with a reproduction. Priority high — user-visible regression."
}
```

### Example 2 — ambiguous

Issue: "What about adding caching?"

Response:
```json
{
  "labels": ["kind/rfc", "area/core", "priority/low"],
  "body_fill": {
    "severity": null,
    "repro": null,
    "acceptance": ["Decision recorded as ADR or `status/blocked` on a concrete dependency"],
    "out_of_scope": []
  },
  "confidence": 0.55,
  "needs_human": true,
  "reasoning": "Open-ended question. Treating as RFC pending clarification on scope and motivation."
}
```
