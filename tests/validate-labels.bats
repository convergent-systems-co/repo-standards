#!/usr/bin/env bats

@test "labels.yml has 28 entries" {
  count=$(yq '.labels | length' labels.yml)
  [ "$count" -eq 28 ]
}

@test "every label has name, color, description" {
  bad=$(yq '.labels[] | select(.name == null or .color == null or .description == null) | .name // "MISSING_NAME"' labels.yml)
  [ -z "$bad" ]
}

@test "every color is a 6-char lowercase hex" {
  bad=$(yq -r '.labels[] | select(.color | test("^[0-9a-f]{6}$") | not) | .name' labels.yml)
  [ -z "$bad" ]
}

@test "all required label names are present" {
  required=(
    kind/bug kind/feature kind/enhancement kind/docs kind/refactor
    kind/chore kind/security kind/rfc
    area/api area/cli area/core area/infra area/ci area/docs area/release
    priority/critical priority/high priority/medium priority/low
    status/triage status/needs-info status/blocked
    resolution/duplicate resolution/wontfix resolution/invalid resolution/completed
    good-first-issue help-wanted
  )
  for name in "${required[@]}"; do
    found=$(yq ".labels[] | select(.name == \"$name\") | .name" labels.yml)
    [ "$found" = "$name" ] || { echo "missing: $name"; return 1; }
  done
}

@test "no duplicate label names" {
  total=$(yq '.labels | length' labels.yml)
  unique=$(yq '[.labels[].name] | unique | length' labels.yml)
  [ "$total" -eq "$unique" ]
}
