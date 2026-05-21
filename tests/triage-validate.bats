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
