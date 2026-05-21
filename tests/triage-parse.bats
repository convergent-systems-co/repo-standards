#!/usr/bin/env bats

PARSE=.github/scripts/triage-parse.sh

@test "extracts valid JSON unchanged" {
  result=$("$PARSE" < tests/fixtures/valid-response.json)
  [ "$(echo "$result" | jq -r .confidence)" = "0.92" ]
}

@test "fails on invalid JSON" {
  run "$PARSE" < tests/fixtures/invalid-json.txt
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid JSON"* ]]
}

@test "extracts JSON from response with prose wrapping" {
  echo 'Here you go: {"labels": ["kind/bug","area/cli","priority/high"], "body_fill": {"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]}, "confidence": 0.7, "needs_human": false, "reasoning": "x"} thanks!' |
    "$PARSE" | jq -e '.confidence == 0.7'
}

@test "extracts JSON from response with markdown fence" {
  printf '```json\n{"labels": ["kind/bug","area/cli","priority/high"], "body_fill": {"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]}, "confidence": 0.7, "needs_human": false, "reasoning": "x"}\n```\n' |
    "$PARSE" | jq -e '.confidence == 0.7'
}
