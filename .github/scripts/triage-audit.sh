#!/usr/bin/env bash
# triage-audit.sh REPO ISSUE_NUMBER METHOD OUTCOME
#   stdin: validated JSON (or empty if outcome=failure)
#   appends one JSONL line to the workflow artifact triage-audit.jsonl

set -euo pipefail

repo="$1"
issue="$2"
method="$3"      # copilot | rest | none
outcome="$4"     # applied | needs_human | rejected | failed
input=$(cat || echo '{}')

line=$(jq -nc \
  --arg chronon "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)" \
  --arg repo    "$repo" \
  --arg issue   "$issue" \
  --arg method  "$method" \
  --arg outcome "$outcome" \
  --argjson agent "$input" \
  '{chronon: $chronon, repo: $repo, issue: ($issue | tonumber), method: $method, outcome: $outcome, agent: $agent}')

echo "$line" >> triage-audit.jsonl
