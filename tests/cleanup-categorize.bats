#!/usr/bin/env bats

SCRIPT=.github/scripts/cleanup-categorize.sh

@test "categorizes standard / aliased / ambiguous / unmapped correctly" {
  result=$("$SCRIPT" labels.yml label-aliases.yml < tests/fixtures/current-labels.json)
  expected=$(cat tests/fixtures/expected-categories.json)
  diff <(echo "$result" | jq -S .) <(echo "$expected" | jq -S .)
}

@test "handles empty current labels" {
  result=$(echo '[]' | "$SCRIPT" labels.yml label-aliases.yml)
  [ "$(echo "$result" | jq '.standard | length')" -eq 0 ]
  [ "$(echo "$result" | jq '.aliased | length')" -eq 0 ]
  [ "$(echo "$result" | jq '.ambiguous | length')" -eq 0 ]
  [ "$(echo "$result" | jq '.unmapped | length')" -eq 0 ]
}

@test "treats null alias values as ambiguous" {
  echo '[{"name":"question","color":"d876e3"}]' |
    "$SCRIPT" labels.yml label-aliases.yml |
    jq -e '.ambiguous == ["question"] and .aliased == []'
}
