#!/usr/bin/env bash
# decompose-parse.sh
#   stdin:  JSON array of issue comments (as returned by
#           `gh api repos/<owner>/<repo>/issues/<n>/comments`)
#   stdout: canonical compact JSON of the LATEST proposal's payload
#   stderr: the proposal SHA on success; descriptive error on failure
#   exit:   0 = found and extracted
#           1 = no proposal marker found
#           2 = malformed JSON inside proposal comment

set -euo pipefail

comments=$(cat)

# Filter to comments containing the proposal marker; pick newest by created_at.
proposal=$(echo "$comments" | jq -c '
  [ .[]
    | select(.body | test("<!--\\s*triage:proposal:v2:sha=[a-f0-9]{12}\\s*-->"))
  ]
  | sort_by(.created_at) | reverse | .[0] // null
')

if [ "$proposal" = "null" ]; then
  echo "ERROR: no proposal comment found" >&2
  exit 1
fi

body=$(echo "$proposal" | jq -r .body)

# Extract the proposal SHA from the marker.
sha=$(echo "$body" \
  | grep -oE '<!--[[:space:]]*triage:proposal:v2:sha=[a-f0-9]{12}[[:space:]]*-->' \
  | head -1 \
  | grep -oE '[a-f0-9]{12}')

# Extract the fenced JSON block (```json ... ```).
json=$(echo "$body" | awk '
  /```json/ { capture=1; next }
  /```/     { if (capture) { capture=0; exit } }
  capture   { print }
')

if [ -z "$json" ] || ! echo "$json" | jq -e . >/dev/null 2>&1; then
  echo "ERROR: malformed JSON inside proposal comment" >&2
  exit 2
fi

# Emit SHA on stderr, canonical compact JSON on stdout.
echo "$sha" >&2
echo "$json" | jq -c .
