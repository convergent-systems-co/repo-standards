#!/usr/bin/env bash
# triage-parse.sh — extract a single JSON object from agent stdin.
# Strips markdown fences and surrounding prose. Validates JSON shape only.

set -euo pipefail

input=$(cat)

# Strip markdown code fences if present (```json ... ``` or ``` ... ```)
stripped=$(echo "$input" | sed -E 's/^[[:space:]]*```(json)?[[:space:]]*$//g' | sed -E 's/^[[:space:]]*```[[:space:]]*$//g')

# Extract JSON by finding the first { and tracking brace nesting
json=""
brace_depth=0
found_start=0

while IFS= read -r line; do
  for ((i=0; i<${#line}; i++)); do
    char="${line:$i:1}"

    # Check if we've found the opening brace
    if [[ "$char" == "{" ]] && [[ $found_start -eq 0 ]]; then
      found_start=1
      brace_depth=1
      json="$char"
    elif [[ $found_start -eq 1 ]]; then
      json+="$char"
      if [[ "$char" == "{" ]]; then
        ((brace_depth++))
      elif [[ "$char" == "}" ]]; then
        ((brace_depth--))
      fi

      # If braces are balanced and we've found content, we're done
      if [[ $brace_depth -eq 0 ]]; then
        break 2  # Break out of both loops
      fi
    fi
  done
done <<< "$stripped"

# Validate we found valid JSON
if [[ -z "$json" ]] || ! echo "$json" | jq -e . >/dev/null 2>&1; then
  echo "ERROR: invalid JSON in agent response" >&2
  exit 1
fi

# Emit the canonical compact form
echo "$json" | jq -c .
