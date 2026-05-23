#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

SCRIPT="$BATS_TEST_DIRNAME/../.github/scripts/decompose-apply.sh"

setup() {
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$BATS_TEST_TMPDIR/gh.log"
# Simulate `gh api ... POST issues` returning a JSON body with .number.
# Match the create-issue endpoint (no sub_issues in path).
case "$*" in
  *"-X POST"*"/issues "*"sub_issues"*|*"sub_issues"*)
    echo '{}'
    ;;
  *"-X POST"*"/issues"*|*"-X POST repos/"*"/issues"*)
    echo '{"number": 999, "html_url": "https://x/issues/999"}'
    ;;
  *"issue view"*) echo '{"body":"original"}' ;;
  *) echo '{}' ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  : > "$BATS_TEST_TMPDIR/gh.log"
}

@test "decompose-apply: creates one POST /issues per child" {
  echo '{
    "parent_level":"feature","child_level":"story","confidence":0.9,
    "needs_human":false,"reasoning":"x",
    "children":[
      {"title":"a","body":"x","labels":["agile/story","kind/feature","area/core","priority/medium"]},
      {"title":"b","body":"x","labels":["agile/story","kind/feature","area/core","priority/medium"]}
    ]
  }' | bash "$SCRIPT" test/repo 42 deadbeef
  count=$(grep -c "POST repos/test/repo/issues " "$BATS_TEST_TMPDIR/gh.log" || true)
  [ "$count" -eq 2 ]
}

@test "decompose-apply: links each new child as a sub-issue of the parent" {
  echo '{
    "parent_level":"feature","child_level":"story","confidence":0.9,
    "needs_human":false,"reasoning":"x",
    "children":[
      {"title":"a","body":"x","labels":["agile/story","kind/feature","area/core","priority/medium"]}
    ]
  }' | bash "$SCRIPT" test/repo 42 deadbeef
  grep -q "POST repos/test/repo/issues/42/sub_issues" "$BATS_TEST_TMPDIR/gh.log"
}

@test "decompose-apply: removes status/triage from parent on success" {
  echo '{
    "parent_level":"feature","child_level":"story","confidence":0.9,
    "needs_human":false,"reasoning":"x",
    "children":[
      {"title":"a","body":"x","labels":["agile/story","kind/feature","area/core","priority/medium"]}
    ]
  }' | bash "$SCRIPT" test/repo 42 deadbeef
  grep -q "remove-label status/triage" "$BATS_TEST_TMPDIR/gh.log"
}

@test "decompose-apply: posts applied marker comment" {
  echo '{
    "parent_level":"feature","child_level":"story","confidence":0.9,
    "needs_human":false,"reasoning":"x",
    "children":[
      {"title":"a","body":"x","labels":["agile/story","kind/feature","area/core","priority/medium"]}
    ]
  }' | bash "$SCRIPT" test/repo 42 deadbeef
  grep -q "triage:applied:v2:sha=deadbeef" "$BATS_TEST_TMPDIR/gh.log"
}
