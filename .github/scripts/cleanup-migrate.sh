#!/usr/bin/env bash
# cleanup-migrate.sh REPO FROM_LABEL TO_LABEL DRY_RUN
#   For each issue carrying FROM_LABEL (open AND closed), add TO_LABEL then
#   remove FROM_LABEL. Then delete FROM_LABEL from the repo.
#   DRY_RUN=true → only log, do not mutate.

set -euo pipefail

repo="$1"
from="$2"
to="$3"
dry="${4:-false}"

# Find all issues with this label
issues=$(gh api "repos/$repo/issues?state=all&labels=$(printf '%s' "$from" | jq -sRr @uri)" \
  --paginate --jq '.[].number')

count=0
for n in $issues; do
  count=$((count + 1))
  if [ "$dry" = "true" ]; then
    echo "  [dry-run] would migrate #$n: +$to, -$from"
  else
    gh issue edit "$n" --repo "$repo" --add-label "$to" >/dev/null
    gh issue edit "$n" --repo "$repo" --remove-label "$from" >/dev/null
    gh issue comment "$n" --repo "$repo" --body "Label cleanup: \`$from\` → \`$to\`" >/dev/null
    echo "  migrated #$n: +$to, -$from"
  fi
done

if [ "$dry" = "true" ]; then
  echo "  [dry-run] would delete repo label: $from"
else
  gh api "repos/$repo/labels/$(printf '%s' "$from" | jq -sRr @uri)" \
    -X DELETE >/dev/null
  echo "  deleted repo label: $from"
fi

echo "$count issues processed for $from → $to"
