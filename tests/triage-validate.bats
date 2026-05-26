#!/usr/bin/env bats

VALIDATE=.github/scripts/triage-validate.sh
LABELS=labels.yml
THRESHOLD=0.6

@test "valid response passes" {
  jq -c . < tests/fixtures/valid-response.json |
    "$VALIDATE" "$LABELS" "$THRESHOLD"
}

@test "missing kind/ fails" {
  run bash -c "jq -c . < tests/fixtures/missing-kind.json | $VALIDATE $LABELS $THRESHOLD"
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing kind/"* ]]
}

@test "non-standard label is dropped, others kept" {
  result=$(jq -c . < tests/fixtures/non-standard-label.json |
    "$VALIDATE" "$LABELS" "$THRESHOLD" 2>&1 || true)
  # Should report the bad label
  [[ "$result" == *"priority/yolo"* ]]
  # Should fail because no valid priority remains
  echo "$result" | grep -qE "missing priority/" || return 1
}

@test "low confidence forces needs_human=true" {
  result=$(jq -c . < tests/fixtures/low-confidence.json |
    "$VALIDATE" "$LABELS" "$THRESHOLD")
  [ "$(echo "$result" | jq .needs_human)" = "true" ]
}

@test "validate: accepts agile/epic alongside kind/feature" {
  run bash .github/scripts/triage-validate.sh labels.yml 0.6 < <(echo '{
    "labels":["kind/feature","area/core","priority/medium","agile/epic"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.85,"needs_human":false,"reasoning":"x"
  }')
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.labels | index("agile/epic")' >/dev/null
}

@test "validate: rejects kind/hook with agile/* (forbidden combo)" {
  run bash .github/scripts/triage-validate.sh labels.yml 0.6 < <(echo '{
    "labels":["kind/hook","area/ci","priority/low","agile/task"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.9,"needs_human":false,"reasoning":"x"
  }')
  [ "$status" -ne 0 ]
  [[ "$output" == *"forbidden"* ]]
}

@test "validate: rejects more than one agile/*" {
  run bash .github/scripts/triage-validate.sh labels.yml 0.6 < <(echo '{
    "labels":["kind/feature","area/core","priority/medium","agile/epic","agile/feature"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.85,"needs_human":false,"reasoning":"x"
  }')
  [ "$status" -ne 0 ]
}
