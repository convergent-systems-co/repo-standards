#!/usr/bin/env bats

setup() {
  ALL_LABELS=$(yq '.labels[].name' labels.yml | tr -d '"')
}

@test "aliases.yml exists and parses" {
  yq '.aliases' label-aliases.yml > /dev/null
}

@test "every non-null alias maps to a real label in labels.yml" {
  bad=$(yq -r '.aliases | to_entries[] | select(.value != null) | .value' label-aliases.yml |
    while read -r target; do
      echo "$ALL_LABELS" | grep -qx "$target" || echo "$target"
    done)
  [ -z "$bad" ]
}

@test "GitHub default labels are all mapped" {
  for src in bug documentation duplicate enhancement "good first issue" "help wanted" invalid wontfix question; do
    has=$(yq ".aliases | has(\"$src\")" label-aliases.yml)
    [ "$has" = "true" ] || { echo "missing alias for: $src"; return 1; }
  done
}
