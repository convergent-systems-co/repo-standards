#!/usr/bin/env bash
# cleanup-categorize.sh LABELS_YML ALIASES_YML
#   stdin:  JSON array of {name, color} (output of `gh api .../labels`)
#   stdout: JSON object {standard, aliased, ambiguous, unmapped}

set -euo pipefail

labels_yml="$1"
aliases_yml="$2"

current=$(cat)

standard=$(yq -o=json -I=0 '[.labels[].name]' "$labels_yml")
aliases_json=$(yq -o=json '.aliases' "$aliases_yml")

jq -nc \
  --argjson current "$current" \
  --argjson standard "$standard" \
  --argjson aliases  "$aliases_json" '
  ($current | map(.name)) as $cur |
  {
    standard:  [$cur[] | select(. as $n | $standard | index($n))],
    aliased:   [$cur[]
                | . as $n
                | select($standard | index($n) | not)
                | select($aliases | has($n))
                | select($aliases[$n] != null)
                | {from: $n, to: $aliases[$n]}],
    ambiguous: [$cur[]
                | . as $n
                | select($standard | index($n) | not)
                | select($aliases | has($n))
                | select($aliases[$n] == null)],
    unmapped:  [$cur[]
                | . as $n
                | select($standard | index($n) | not)
                | select($aliases | has($n) | not)]
  }'
