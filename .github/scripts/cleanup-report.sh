#!/usr/bin/env bash
# cleanup-report.sh CATEGORIES_JSON ISSUES_JSON RUN_NUMBER
#   Emits markdown for the cleanup report issue.

set -euo pipefail

cats="$1"
issues="$2"
run="$3"

migrated=$(jq -r '.aliased[] | "| `\(.from)` | `\(.to)` |"' "$cats")
ambiguous=$(jq -r '.ambiguous[]' "$cats")
unmapped=$(jq -r '.unmapped[]' "$cats")

# Count issues per stray label
issue_links() {
  local label="$1"
  jq -r --arg L "$label" '[.[] | select(.labels | index($L)) | "#\(.n)"] | join(", ")' "$issues"
}

cat <<EOF
# Label cleanup report — run #$run — $(date -u +%Y-%m-%d)

This issue is updated by .github/workflows/label-cleanup.yml.
Standards source: \`repo-standards@v1\` (\`labels.yml\`, \`label-aliases.yml\`).

## Ambiguous (needs human decision)

| Label | Sample issues |
|---|---|
$(for L in $ambiguous; do
    echo "| \`$L\` | $(issue_links "$L") |"
  done)

Decide per label: add a mapping to \`label-aliases.yml\` (PR to repo-standards), then re-run.

## Unmapped (no alias known)

| Label | Sample issues |
|---|---|
$(for L in $unmapped; do
    echo "| \`$L\` | $(issue_links "$L") |"
  done)

## Migrated this run

| From | To |
|---|---|
$migrated
EOF
