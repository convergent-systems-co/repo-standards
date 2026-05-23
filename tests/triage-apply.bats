#!/usr/bin/env bats

# Tests for triage-apply.sh status/triage lifecycle decisions.
# Mock gh by overriding it on PATH; capture invocations to a temp log.

setup() {
  # Ensure bash 4+ is on PATH (macOS ships bash 3.2; homebrew provides 5+).
  # triage-apply.sh uses mapfile which requires bash 4+.
  export PATH="$BATS_TEST_TMPDIR/bin:/opt/homebrew/bin:$PATH"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$BATS_TEST_TMPDIR/gh.log"
case "$*" in
  *"issue view"*) echo "original body" ;;
  *) : ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  : > "$BATS_TEST_TMPDIR/gh.log"
}

@test "apply: agile/task leaf → status/triage REMOVED" {
  echo '{
    "labels":["kind/feature","area/core","priority/medium","agile/task"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.9,"needs_human":false,"reasoning":"x"
  }' | bash .github/scripts/triage-apply.sh test/repo 1
  grep -q "remove-label status/triage" "$BATS_TEST_TMPDIR/gh.log"
}

@test "apply: kind/hook leaf → status/triage REMOVED" {
  echo '{
    "labels":["kind/hook","area/ci","priority/low"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.9,"needs_human":false,"reasoning":"x"
  }' | bash .github/scripts/triage-apply.sh test/repo 1
  grep -q "remove-label status/triage" "$BATS_TEST_TMPDIR/gh.log"
}

@test "apply: kind/finding leaf → status/triage REMOVED" {
  echo '{
    "labels":["kind/finding","area/core","priority/medium"],
    "body_fill":{"severity":"medium","repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.9,"needs_human":false,"reasoning":"x"
  }' | bash .github/scripts/triage-apply.sh test/repo 1
  grep -q "remove-label status/triage" "$BATS_TEST_TMPDIR/gh.log"
}

@test "apply: agile/epic decomposable → status/triage STAYS" {
  echo '{
    "labels":["kind/feature","area/core","priority/medium","agile/epic"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.85,"needs_human":false,"reasoning":"x"
  }' | bash .github/scripts/triage-apply.sh test/repo 1
  ! grep -q "remove-label status/triage" "$BATS_TEST_TMPDIR/gh.log"
}

@test "apply: agile/feature decomposable → status/triage STAYS" {
  echo '{
    "labels":["kind/feature","area/core","priority/medium","agile/feature"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.85,"needs_human":false,"reasoning":"x"
  }' | bash .github/scripts/triage-apply.sh test/repo 1
  ! grep -q "remove-label status/triage" "$BATS_TEST_TMPDIR/gh.log"
}

@test "apply: needs_human=true → status/needs-info ADDED, triage stays" {
  echo '{
    "labels":["kind/rfc","area/core","priority/low"],
    "body_fill":{"severity":null,"repro":null,"acceptance":["x"],"out_of_scope":[]},
    "confidence":0.4,"needs_human":true,"reasoning":"x"
  }' | bash .github/scripts/triage-apply.sh test/repo 1
  grep -q "add-label status/needs-info" "$BATS_TEST_TMPDIR/gh.log"
  ! grep -q "remove-label status/triage" "$BATS_TEST_TMPDIR/gh.log"
}
