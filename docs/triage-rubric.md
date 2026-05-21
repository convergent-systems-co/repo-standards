# Triage Rubric — convergent-systems-co

This rubric is the prompt the triage pipeline gives to the agent (GitHub Copilot
primary, REST API fallback) for every incoming issue. The agent reads the issue
body and produces a single JSON object — no prose, no markdown fences.

> This file is the **initial scaffold**. The full rubric (decision tree, response
> schema, edge cases) is added in Plan 2 alongside the triage workflow.

## Response shape (strict)

```json
{
  "labels": ["kind/<x>", "area/<x>", "priority/<x>"],
  "body_fill": {
    "severity": "low|medium|high|critical|null",
    "repro": "string|null",
    "acceptance": ["string", "..."],
    "out_of_scope": ["string", "..."]
  },
  "confidence": 0.0,
  "needs_human": false,
  "reasoning": "1-3 sentences for the audit log"
}
```

## Decision tree

(Populated by Plan 2.)
