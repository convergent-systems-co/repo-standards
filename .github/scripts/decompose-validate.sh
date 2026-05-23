#!/usr/bin/env bash
# decompose-validate.sh LABELS_YML CONFIDENCE_THRESHOLD
#   stdin:  decomposition JSON (from agent)
#   stdout: validated/normalized JSON (needs_human forced if below threshold)
#   exit:   0 = valid; 2 = missing required field; 3 = hierarchy mismatch;
#           4 = child shape violation; 5 = prompt-injection suspected

set -euo pipefail

labels_yml="$1"
threshold="${2:-0.7}"

raw=$(cat)

# 1. Required top-level fields
for field in parent_level child_level confidence needs_human reasoning children; do
  if ! echo "$raw" | jq -e "has(\"$field\")" >/dev/null; then
    echo "ERROR: missing required field: $field" >&2
    exit 2
  fi
done

parent_level=$(echo "$raw" | jq -r .parent_level)
child_level=$(echo "$raw" | jq -r .child_level)

# 2. Hierarchy mapping: parent → child must be exactly one step down
expected_child=""
case "$parent_level" in
  epic)    expected_child="feature" ;;
  feature) expected_child="story"   ;;
  story)   expected_child="task"    ;;
  *)
    echo "ERROR: parent_level '$parent_level' is not decomposable" >&2
    exit 3
    ;;
esac
if [ "$child_level" != "$expected_child" ]; then
  echo "ERROR: hierarchy mismatch: parent=$parent_level requires child=$expected_child, got $child_level" >&2
  exit 3
fi

# 3. Children count: 1..10
child_count=$(echo "$raw" | jq '.children | length')
if [ "$child_count" -lt 1 ]; then
  echo "ERROR: children array is empty; emit needs_human=true at agent level" >&2
  exit 4
fi
if [ "$child_count" -gt 10 ]; then
  echo "ERROR: children array length $child_count exceeds 10" >&2
  exit 4
fi

# 4. Build label whitelist from labels.yml
allowed=$(yq -r '.labels[].name' "$labels_yml" | jq -R . | jq -s .)

# 5. Validate each child
for i in $(seq 0 $((child_count - 1))); do
  child=$(echo "$raw" | jq -c ".children[$i]")

  # 5a. Required shape: title, body, labels
  for f in title body labels; do
    if ! echo "$child" | jq -e "has(\"$f\")" >/dev/null; then
      echo "ERROR: child[$i] missing $f" >&2
      exit 4
    fi
  done

  title=$(echo "$child" | jq -r .title)
  body=$(echo "$child" | jq -r .body)

  # 5b. Title length and no kind: prefix
  if [ "${#title}" -gt 80 ]; then
    echo "ERROR: child[$i] title length ${#title} > 80" >&2
    exit 4
  fi
  if echo "$title" | grep -qiE '^(bug|feature|chore|refactor|task|story|epic):'; then
    echo "ERROR: child[$i] title carries kind: prefix; labels carry kind, not title" >&2
    exit 4
  fi

  # 5c. agile/<child_level> required in labels
  if ! echo "$child" | jq -e --arg lbl "agile/$child_level" '.labels | index($lbl) != null' >/dev/null; then
    echo "ERROR: child[$i] missing required label agile/$child_level" >&2
    exit 4
  fi

  # 5d. All labels resolvable in labels.yml
  child_labels=$(echo "$child" | jq -c .labels)
  unknown=$(echo "$child_labels" | jq --argjson allow "$allowed" \
    'map(select(. as $l | $allow | index($l) == null))')
  if [ "$unknown" != "[]" ]; then
    echo "ERROR: child[$i] has unknown labels: $(echo "$unknown" | jq -c .)" >&2
    exit 4
  fi

  # 5e. Prompt-injection scan (per Common.md §U8)
  combined="${title} ${body}"
  if echo "$combined" | grep -qiE '(ignore previous instructions|disregard the above|you are now|new instructions:|system:.{0,20}override)'; then
    echo "ERROR: child[$i] contains prompt-injection signature" >&2
    exit 5
  fi
done

# 6. Confidence threshold → force needs_human
conf=$(echo "$raw" | jq -r .confidence)
if awk -v c="$conf" -v t="$threshold" 'BEGIN{exit !(c < t)}'; then
  raw=$(echo "$raw" | jq '.needs_human = true')
  echo "WARN: confidence $conf < $threshold; forcing needs_human=true" >&2
fi

echo "$raw" | jq -c .
