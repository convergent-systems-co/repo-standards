#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

SCRIPT="$BATS_TEST_DIRNAME/../.github/scripts/decompose-parse.sh"

@test "decompose-parse: extracts JSON from a single proposal comment" {
  cat > "$BATS_TEST_TMPDIR/comments.json" <<'EOF'
[
  {
    "id": 1,
    "body": "Proposal for #42:\n\n```json\n{\"parent_level\":\"feature\",\"child_level\":\"story\",\"children\":[]}\n```\n\n<!-- triage:proposal:v2:sha=abc123def456 -->",
    "created_at": "2026-05-23T10:00:00Z"
  }
]
EOF
  run --separate-stderr bash "$SCRIPT" < "$BATS_TEST_TMPDIR/comments.json"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.parent_level == "feature"' >/dev/null
}

@test "decompose-parse: picks the LATEST proposal when multiple exist" {
  cat > "$BATS_TEST_TMPDIR/comments.json" <<'EOF'
[
  {
    "id": 1,
    "body": "OLD\n```json\n{\"parent_level\":\"feature\",\"child_level\":\"story\",\"old\":true}\n```\n<!-- triage:proposal:v2:sha=aaaaaaaaaaaa -->",
    "created_at": "2026-05-23T10:00:00Z"
  },
  {
    "id": 2,
    "body": "NEW\n```json\n{\"parent_level\":\"feature\",\"child_level\":\"story\",\"old\":false}\n```\n<!-- triage:proposal:v2:sha=bbbbbbbbbbbb -->",
    "created_at": "2026-05-23T11:00:00Z"
  }
]
EOF
  run --separate-stderr bash "$SCRIPT" < "$BATS_TEST_TMPDIR/comments.json"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.old == false' >/dev/null
}

@test "decompose-parse: fails with non-zero when no proposal marker exists" {
  cat > "$BATS_TEST_TMPDIR/comments.json" <<'EOF'
[
  {
    "id": 1,
    "body": "Just a regular comment, no marker.",
    "created_at": "2026-05-23T10:00:00Z"
  }
]
EOF
  run --separate-stderr bash "$SCRIPT" < "$BATS_TEST_TMPDIR/comments.json"
  [ "$status" -ne 0 ]
}

@test "decompose-parse: emits applied-marker hash on stderr" {
  cat > "$BATS_TEST_TMPDIR/comments.json" <<'EOF'
[
  {
    "id": 1,
    "body": "P\n```json\n{}\n```\n<!-- triage:proposal:v2:sha=deadbeefcafe -->",
    "created_at": "2026-05-23T10:00:00Z"
  }
]
EOF
  run --separate-stderr bash "$SCRIPT" < "$BATS_TEST_TMPDIR/comments.json"
  [[ "$stderr" == *"deadbeefcafe"* ]]
}

@test "decompose-parse: respects human edits (re-reads JSON from comment body)" {
  cat > "$BATS_TEST_TMPDIR/comments.json" <<'EOF'
[
  {
    "id": 1,
    "body": "Original then EDITED to add a child:\n\n```json\n{\"parent_level\":\"feature\",\"child_level\":\"story\",\"children\":[{\"title\":\"human-added\"}]}\n```\n<!-- triage:proposal:v2:sha=aaaaaaaaaaaa -->",
    "created_at": "2026-05-23T10:00:00Z",
    "updated_at": "2026-05-23T10:30:00Z"
  }
]
EOF
  run --separate-stderr bash "$SCRIPT" < "$BATS_TEST_TMPDIR/comments.json"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.children[0].title == "human-added"' >/dev/null
}
