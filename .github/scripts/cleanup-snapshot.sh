#!/usr/bin/env bash
# cleanup-snapshot.sh REPO OUT_PATH
#   Writes snapshot JSON to OUT_PATH. Captures:
#     - All labels (name, color, description)
#     - Per-issue label assignments (open AND closed; includes PRs)
#   Format:
#     { "repo": "...", "captured_at": "...", "labels": [...], "issues": [...] }

set -euo pipefail

repo="$1"
out="$2"

labels=$(gh api "repos/$repo/labels" --paginate)
issues=$(gh api "repos/$repo/issues?state=all" --paginate --jq \
  '[.[] | {n: .number, labels: [.labels[].name]}]')

jq -nc \
  --arg repo "$repo" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson labels "$labels" \
  --argjson issues "$issues" \
  '{repo: $repo, captured_at: $ts, labels: $labels, issues: $issues}' > "$out"

echo "snapshot written to $out ($(wc -c < "$out") bytes)"
