#!/usr/bin/env bash
# triage-apply.sh REPO ISSUE_NUMBER
#   stdin:  validated JSON from triage-validate.sh
#   side effects:
#     - applies suggested labels
#     - removes status/triage if needs_human=false
#     - adds status/needs-info if needs_human=true
#     - inserts body_fill sections at top of issue body, above an HR separator
#     - posts a single audit comment

set -euo pipefail

repo="$1"
issue="$2"
json=$(cat)

needs_human=$(echo "$json" | jq -r .needs_human)
labels=$(echo "$json" | jq -r '.labels[]')
confidence=$(echo "$json" | jq -r .confidence)
reasoning=$(echo "$json" | jq -r .reasoning)

# Apply labels
while read -r label; do
  gh issue edit "$issue" --repo "$repo" --add-label "$label" >/dev/null
done <<< "$labels"

# Status handling
if [ "$needs_human" = "true" ]; then
  gh issue edit "$issue" --repo "$repo" --add-label "status/needs-info" >/dev/null
else
  gh issue edit "$issue" --repo "$repo" --remove-label "status/triage" >/dev/null
fi

# Build body_fill sections
sev=$(echo "$json" | jq -r '.body_fill.severity // empty')
repro=$(echo "$json" | jq -r '.body_fill.repro // empty')
mapfile -t acceptance < <(echo "$json" | jq -r '.body_fill.acceptance[]?')
mapfile -t oos        < <(echo "$json" | jq -r '.body_fill.out_of_scope[]?')

sections=""
[ -n "$sev"   ] && sections+="**Severity:** $sev"$'\n\n'
[ -n "$repro" ] && sections+="**Reproduction:**"$'\n\n'"$repro"$'\n\n'
if [ "${#acceptance[@]}" -gt 0 ]; then
  sections+="**Acceptance criteria:**"$'\n'
  for a in "${acceptance[@]}"; do sections+="- $a"$'\n'; done
  sections+=$'\n'
fi
if [ "${#oos[@]}" -gt 0 ]; then
  sections+="**Out of scope:**"$'\n'
  for o in "${oos[@]}"; do sections+="- $o"$'\n'; done
  sections+=$'\n'
fi

if [ -n "$sections" ]; then
  current=$(gh issue view "$issue" --repo "$repo" --json body --jq .body)
  # Only insert if no triage block exists yet
  if [[ "$current" != *"<!-- triage:fill -->"* ]]; then
    new="<!-- triage:fill -->"$'\n'"$sections"$'\n'"---"$'\n\n'"$current"
    gh issue edit "$issue" --repo "$repo" --body "$new" >/dev/null
  fi
fi

# Audit comment
gh issue comment "$issue" --repo "$repo" --body "Triaged by @copilot.
- Labels: $(echo "$labels" | paste -sd ',' -)
- Confidence: $confidence
- Reasoning: $reasoning

Override with \`/triage\` to re-run, or \`/triage:hold\` to pause." >/dev/null
