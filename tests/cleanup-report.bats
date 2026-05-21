#!/usr/bin/env bats

SCRIPT=.github/scripts/cleanup-report.sh

@test "report contains ambiguous and unmapped sections" {
  report=$("$SCRIPT" \
    tests/fixtures/expected-categories.json \
    tests/fixtures/sample-issues.json \
    "1234")
  [[ "$report" == *"## Ambiguous"* ]]
  [[ "$report" == *"## Unmapped"* ]]
  [[ "$report" == *"question"* ]]
  [[ "$report" == *"wishlist"* ]]
}

@test "report links sample issues per stray" {
  report=$("$SCRIPT" \
    tests/fixtures/expected-categories.json \
    tests/fixtures/sample-issues.json \
    "1234")
  [[ "$report" == *"#3"* ]]   # the one issue carrying "question"
  [[ "$report" == *"#4"* ]]   # the one issue carrying "wishlist"
}

@test "report includes migration audit table" {
  report=$("$SCRIPT" \
    tests/fixtures/expected-categories.json \
    tests/fixtures/sample-issues.json \
    "1234")
  [[ "$report" == *"## Migrated this run"* ]]
  [[ "$report" == *"bug"* ]]
  [[ "$report" == *"kind/bug"* ]]
}
