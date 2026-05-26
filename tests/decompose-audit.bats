#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

SCRIPT="$BATS_TEST_DIRNAME/../.github/scripts/decompose-audit.sh"

@test "decompose-audit: appends a JSONL line for propose event" {
  cd "$BATS_TEST_TMPDIR"
  echo '{"parent_level":"feature","child_level":"story","children":[{},{}]}' | \
    bash "$SCRIPT" propose test/repo 42 copilot proposed deadbeef "bodyha" "12345"
  [ -f decompose-audit.jsonl ]
  line=$(cat decompose-audit.jsonl)
  echo "$line" | jq -e '.event == "propose"' >/dev/null
  echo "$line" | jq -e '.issue == 42' >/dev/null
  echo "$line" | jq -e '.outcome == "proposed"' >/dev/null
  echo "$line" | jq -e '.child_count == 2' >/dev/null
  echo "$line" | jq -e '.chronon | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{3}Z$")' >/dev/null
  echo "$line" | jq -e '.body_sha == "bodyha"' >/dev/null
  echo "$line" | jq -e '.run_id == "12345"' >/dev/null
}

@test "decompose-audit: appends a JSONL line for approve event" {
  cd "$BATS_TEST_TMPDIR"
  echo '{"children_filed":[101,102]}' | \
    bash "$SCRIPT" approve test/repo 42 alice MEMBER applied beefcafe "12345"
  [ -f decompose-audit.jsonl ]
  line=$(cat decompose-audit.jsonl)
  echo "$line" | jq -e '.event == "approve"' >/dev/null
  echo "$line" | jq -e '.actor == "alice"' >/dev/null
  echo "$line" | jq -e '.author_association == "MEMBER"' >/dev/null
  echo "$line" | jq -e '.outcome == "applied"' >/dev/null
  echo "$line" | jq -e '.chronon | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\.[0-9]{3}Z$")' >/dev/null
  echo "$line" | jq -e '.run_id == "12345"' >/dev/null
}

@test "decompose-audit: propose event includes proposal_sha" {
  cd "$BATS_TEST_TMPDIR"
  echo '{"children":[]}' | \
    bash "$SCRIPT" propose test/repo 42 copilot proposed cafebabe "bodyha" "12345"
  line=$(cat decompose-audit.jsonl)
  echo "$line" | jq -e '.proposal_sha == "cafebabe"' >/dev/null
}

@test "decompose-audit: approve event includes proposal_sha" {
  cd "$BATS_TEST_TMPDIR"
  echo '{"children_filed":[]}' | \
    bash "$SCRIPT" approve test/repo 42 alice MEMBER applied cafebabe "12345"
  line=$(cat decompose-audit.jsonl)
  echo "$line" | jq -e '.proposal_sha == "cafebabe"' >/dev/null
}

@test "decompose-audit: fails on unknown event type" {
  cd "$BATS_TEST_TMPDIR"
  run bash "$SCRIPT" unknown test/repo 42
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown event"* ]]
}

@test "decompose-audit: multiple appends create separate JSONL lines" {
  cd "$BATS_TEST_TMPDIR"
  echo '{"children":[{},{}]}' | \
    bash "$SCRIPT" propose test/repo 42 copilot proposed abc123 "bodyha" "11111"
  echo '{"children_filed":[101]}' | \
    bash "$SCRIPT" approve test/repo 42 alice MEMBER applied def456 "22222"
  [ "$(wc -l < decompose-audit.jsonl)" -eq 2 ]
  head -1 decompose-audit.jsonl | jq -e '.event == "propose"' >/dev/null
  tail -1 decompose-audit.jsonl | jq -e '.event == "approve"' >/dev/null
}

@test "decompose-audit: propose body_sha and run_id default to empty string when omitted" {
  cd "$BATS_TEST_TMPDIR"
  echo '{"children":[]}' | \
    bash "$SCRIPT" propose test/repo 42 copilot proposed deadbeef
  line=$(cat decompose-audit.jsonl)
  echo "$line" | jq -e '.body_sha == ""' >/dev/null
  echo "$line" | jq -e '.run_id == ""' >/dev/null
}

@test "decompose-audit: approve run_id defaults to empty string when omitted" {
  cd "$BATS_TEST_TMPDIR"
  echo '{"children_filed":[]}' | \
    bash "$SCRIPT" approve test/repo 42 alice MEMBER applied beefcafe
  line=$(cat decompose-audit.jsonl)
  echo "$line" | jq -e '.run_id == ""' >/dev/null
}
