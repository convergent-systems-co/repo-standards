#!/usr/bin/env bash
# cleanup-rollback.sh REPO SNAPSHOT_JSON DRY_RUN
#   Restores labels and per-issue label state from a snapshot.
#   Treated as a destructive operation by the workflow that wraps it.

set -euo pipefail

repo="$1"
snap="$2"
dry="${3:-false}"

# 1. Restore label definitions (recreate any that were deleted; patch existing)
jq -c '.labels[]' "$snap" | while read -r label; do
  name=$(echo "$label" | jq -r .name)
  color=$(echo "$label" | jq -r .color)
  desc=$(echo "$label" | jq -r '.description // ""')

  if [ "$dry" = "true" ]; then
    echo "  [dry-run] restore label: $name"
    continue
  fi

  existing=$(gh api "repos/$repo/labels/$(printf '%s' "$name" | jq -sRr @uri)" 2>/dev/null || echo "")
  if [ -z "$existing" ]; then
    gh api "repos/$repo/labels" \
      -X POST --input - <<< "{\"name\":\"${name}\",\"color\":\"${color}\",\"description\":\"${desc}\"}" >/dev/null
    echo "  recreated: $name"
  else
    gh api "repos/$repo/labels/$(printf '%s' "$name" | jq -sRr @uri)" \
      -X PATCH --input - <<< "{\"new_name\":\"${name}\",\"color\":\"${color}\",\"description\":\"${desc}\"}" >/dev/null
    echo "  patched: $name"
  fi
done

# 2. Restore per-issue label state (set, not merge — overwrites current)
jq -c '.issues[]' "$snap" | while read -r issue; do
  n=$(echo "$issue" | jq -r .n)
  labels_csv=$(echo "$issue" | jq -r '.labels | join(",")')

  if [ "$dry" = "true" ]; then
    echo "  [dry-run] set #$n labels: $labels_csv"
    continue
  fi

  # Use PUT to replace
  body=$(echo "$issue" | jq '{labels: .labels}')
  gh api "repos/$repo/issues/$n/labels" -X PUT --input - <<< "$body" >/dev/null
  echo "  restored #$n: $labels_csv"
done
