#!/usr/bin/env bash
# decompose-apply.sh REPO PARENT_ISSUE PROPOSAL_SHA
#   stdin: validated decomposition JSON
#   side effects:
#     - for each child: POST /repos/{repo}/issues
#                       POST /repos/{repo}/issues/{parent}/sub_issues
#     - remove status/triage from parent
#     - post applied-marker comment

set -euo pipefail

repo="$1"
parent="$2"
proposal_sha="$3"
json=$(cat)

child_count=$(echo "$json" | jq '.children | length')
created_numbers=()
failed_count=0

for i in $(seq 0 $((child_count - 1))); do
  child=$(echo "$json" | jq -c ".children[$i]")
  title=$(echo "$child" | jq -r .title)
  body=$(echo "$child"  | jq -r .body)
  # Prepend Parent: #N to the body
  body_with_parent="Parent: #${parent}"$'\n\n'"$body"
  labels_json=$(echo "$child" | jq -c '.labels')

  # Ensure status/triage is on the child
  labels_with_triage=$(echo "$labels_json" | jq 'if index("status/triage") == null then . + ["status/triage"] else . end')

  # Idempotency: if a sub-issue with this title already exists under this parent, skip.
  # Use pipe-to-jq with --arg to avoid shell-injection via title content.
  existing=$(gh api "repos/$repo/issues/$parent/sub_issues" --paginate 2>/dev/null \
    | jq --arg t "$title" 'first(.[] | select(.title == $t)) // empty' 2>/dev/null \
    || echo "")
  if [ -n "$existing" ]; then
    existing_num=$(echo "$existing" | jq -r '.number')
    echo "INFO: child '$title' already exists as #$existing_num; skipping" >&2
    created_numbers+=("$existing_num")
    continue
  fi

  # Create the child issue
  # Use -F (JSON-typed field) for labels so the array is sent as a JSON array,
  # not a literal string. --raw-field/-f sends the value as-is (string only).
  child_resp=$(gh api -X POST "repos/$repo/issues" \
    -f "title=$title" \
    -f "body=$body_with_parent" \
    -F "labels=$(echo "$labels_with_triage" | jq -c .)" \
    2>/dev/null || true)

  child_num=$(echo "$child_resp" | jq -r '.number // empty')
  if [ -z "$child_num" ]; then
    echo "ERROR: failed to create child '$title'" >&2
    failed_count=$((failed_count + 1))
    continue
  fi

  # Link as sub-issue of parent
  gh api -X POST "repos/$repo/issues/$parent/sub_issues" \
    -F "sub_issue_id=$child_num" >/dev/null 2>&1 || {
      echo "WARN: child #$child_num created but sub-issue link failed" >&2
    }

  created_numbers+=("$child_num")
done

# Partial failure: do NOT post the applied-marker so the caller can retry.
if [ "$failed_count" -gt 0 ]; then
  echo "WARN: $failed_count children failed to create; re-run /triage approve-decomposition to retry" >&2
  echo "Partial failure: $failed_count of $child_count children not created. Applied-marker NOT posted; safe to retry." >&2
  exit 1
fi

# Full success only: remove status/triage from parent and post applied-marker.
# Doing this after the failure-check prevents the marker from blocking retries
# when some children were not created (per spec §7.1 idempotency contract).
gh issue edit "$parent" --repo "$repo" --remove-label "status/triage" >/dev/null 2>&1 || true

# Post applied-marker comment
if [ "${#created_numbers[@]}" -gt 0 ]; then
  created_list=$(printf '#%s, ' "${created_numbers[@]}" | sed 's/, $//')
else
  created_list="(none)"
fi
gh issue comment "$parent" --repo "$repo" --body "Decomposition applied. Created: $created_list

<!-- triage:applied:v2:sha=$proposal_sha -->" >/dev/null
