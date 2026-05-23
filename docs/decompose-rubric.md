# Decomposition Rubric — convergent-systems-co (v2)

You are decomposing a GitHub issue. The issue's parent_level is given. Your
job is to propose CHILDREN one level beneath the parent, in the agile/*
hierarchy:

    agile/epic    → propose agile/feature children
    agile/feature → propose agile/story  children
    agile/story   → propose agile/task   children
    agile/task    → terminal (you will NEVER be invoked at this level)

Produce a SINGLE JSON object — no prose, no markdown code fences, no
commentary outside the JSON.

## Response schema (strict)

```json
{
  "parent_level": "epic|feature|story",
  "child_level": "feature|story|task",
  "confidence": 0.0,
  "needs_human": false,
  "reasoning": "1-3 sentences",
  "children": [
    {
      "title": "string (≤ 80 chars, NO 'kind:' prefix)",
      "body": "markdown string, may include acceptance criteria",
      "labels": [
        "agile/<child_level>",
        "kind/<...>",
        "area/<...>",
        "priority/<...>"
      ]
    }
  ]
}
```

## Hard rules

- `parent_level + 1 = child_level` exactly. epic→feature, feature→story, story→task. Any other mapping is a violation.
- `children` length is 1–10. Length 0 = "decomposition not warranted; should have stayed a leaf" — emit `needs_human: true` instead with a 0-length children array. Length > 10 = parent is too big for one pass — emit `needs_human: true` and ≤10 children that you would START with.
- Every child's `labels` MUST contain `agile/<child_level>`. Other labels (`kind/*`, `area/*`, `priority/*`) are RECOMMENDED but if absent the parent workflow inherits them from the parent.
- Every child's `title` is ≤ 80 chars. NEVER include a `kind:` prefix like "Bug: foo" — labels carry the kind, not the title.
- Every child's `body` is well-formed markdown. Include acceptance criteria for `agile/story` and `agile/task` children. For `agile/feature` children, describe what the feature delivers.
- DO NOT include the parent's title verbatim in any child title.
- DO NOT propose duplicate children (titles must be distinct within the array).
- DO NOT propose children that are smaller than the parent's natural granularity (a feature that decomposes into 5 trivial tasks instead of 3 stories is a smell — emit `needs_human: true`).

## Decomposition guidelines per level

### epic → features

A feature is a single user-visible CAPABILITY, deliverable in weeks. Group by USER VALUE, not by technical layer.

- Bad: "Backend changes", "Frontend changes", "Database changes" — these are technical layers, not features.
- Good: "OAuth2 login flow", "Password reset", "MFA enrollment" — each delivers value end-to-end.

### feature → stories

A story is a single DELIVERABLE within the feature, completable in a sprint.

- Bad: "Implement", "Test", "Document" — these are workflow phases, not stories.
- Good: "OAuth2 callback handler", "Session cookie refresh", "Logout flow" — each is a coherent slice.

### story → tasks

A task is a single CONCRETE ACTION, completable in hours.

- Bad: "Write code" — too vague.
- Good: "Add unit test for token exchange", "Implement the /auth/callback handler", "Add logging at the error path" — each is unambiguous.

## Confidence calibration

- 0.85+ — the children are obvious to any reader of the parent body
- 0.7–0.85 — some judgement involved but you stand by it
- 0.5–0.7 — significant judgement; flag `needs_human: true`
- <0.5 — guessing; ALWAYS `needs_human: true` and surface in `reasoning`

## Examples

### Example: epic → features

Parent body (`agile/epic`):
> Build the authentication system supporting OAuth2, password login, MFA, password reset, session management, and admin user impersonation.

Response:
```json
{
  "parent_level": "epic",
  "child_level": "feature",
  "confidence": 0.85,
  "needs_human": false,
  "reasoning": "Six explicit user-visible capabilities named in the body — one feature each.",
  "children": [
    {
      "title": "OAuth2 login flow",
      "body": "Users can sign in using a configured OAuth2 provider.\n\n**Acceptance:**\n- Provider list configurable per environment\n- Successful auth establishes a session\n- Failures surface a clear error",
      "labels": ["agile/feature", "kind/feature", "area/core", "priority/high"]
    },
    {
      "title": "Password-based login",
      "body": "Users with local accounts can sign in by email + password.\n\n**Acceptance:**\n- Password compared with constant-time hash verification\n- Rate-limited per identity\n- Lockout after N failures",
      "labels": ["agile/feature", "kind/feature", "area/core", "priority/high"]
    },
    {
      "title": "MFA enrollment and challenge",
      "body": "Users can enroll TOTP, and the second factor is required on each session.\n\n**Acceptance:**\n- TOTP enroll flow\n- Challenge on login\n- Backup-code recovery",
      "labels": ["agile/feature", "kind/feature", "area/core", "priority/high"]
    },
    {
      "title": "Password reset",
      "body": "Users can reset a forgotten password via a one-time email link.\n\n**Acceptance:**\n- Token expires in 30 min\n- One-time use\n- Audit-logged",
      "labels": ["agile/feature", "kind/feature", "area/core", "priority/medium"]
    },
    {
      "title": "Session management",
      "body": "Sessions are revocable, with explicit listing per user.\n\n**Acceptance:**\n- User can list active sessions\n- User can revoke any session\n- Admin can revoke another user's session",
      "labels": ["agile/feature", "kind/feature", "area/core", "priority/medium"]
    },
    {
      "title": "Admin user impersonation",
      "body": "Authorized admins can impersonate a user with full audit trail.\n\n**Acceptance:**\n- Impersonation only with explicit admin grant\n- All impersonated actions audit-logged\n- Banner visible to admin during impersonation",
      "labels": ["agile/feature", "kind/feature", "area/core", "priority/medium"]
    }
  ]
}
```

### Example: needs_human (too big)

Parent body (`agile/feature`):
> Rebuild the entire UI in React. Touches every page.

Response:
```json
{
  "parent_level": "feature",
  "child_level": "story",
  "confidence": 0.4,
  "needs_human": true,
  "reasoning": "Scope is multi-quarter and crosses every surface; closer to an epic than a feature. Human should re-label parent as agile/epic and re-decompose.",
  "children": []
}
```
