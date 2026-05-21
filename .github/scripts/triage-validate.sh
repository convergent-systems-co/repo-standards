#!/usr/bin/env bash
# triage-validate.sh LABELS_YML CONFIDENCE_THRESHOLD
#   stdin:  agent JSON
#   stdout: validated/normalized JSON (with bad labels stripped, needs_human forced)
#   exit:   0 = valid (possibly with warnings to stderr); non-zero = unfixable

set -euo pipefail

labels_yml="$1"
threshold="${2:-0.6}"

raw=$(cat)

# 1. Required top-level fields
for field in labels body_fill confidence needs_human reasoning; do
  if ! echo "$raw" | jq -e "has(\"$field\")" >/dev/null; then
    echo "ERROR: missing required field: $field" >&2
    exit 2
  fi
done

# 2. Build whitelist from labels.yml
whitelist=$(yq -r '.labels[].name' "$labels_yml")

# 3. Filter labels against whitelist; warn on rejects
# Convert whitelist to JSON array for jq
allowed_labels=$(echo "$whitelist" | jq -R . | jq -s .)

# Extract original labels and filter
original_labels=$(echo "$raw" | jq -c .labels)
filtered_labels=$(echo "$raw" | jq --argjson allow "$allowed_labels" \
  '.labels | map(select(. as $l | $allow | index($l) != null))')

# Compute rejected labels (set difference)
rejected=$(echo "$original_labels" | jq --argjson filtered "$filtered_labels" \
  '. as $orig | $orig | map(select(. as $l | $filtered | index($l) == null))')

if [ "$rejected" != "[]" ]; then
  echo "WARN: dropped non-standard labels: $(echo "$rejected" | jq -c .)" >&2
fi

# Apply filtered labels to raw object
filtered=$(echo "$raw" | jq --argjson new_labels "$filtered_labels" \
  '.labels = $new_labels')

# 4. Enforce: exactly 1 kind/, ≥1 area/, exactly 1 priority/
kind_count=$(echo "$filtered" | jq '[.labels[] | select(startswith("kind/"))] | length')
area_count=$(echo "$filtered" | jq '[.labels[] | select(startswith("area/"))] | length')
pri_count=$(echo "$filtered"  | jq '[.labels[] | select(startswith("priority/"))] | length')

if [ "$kind_count" -ne 1 ]; then
  echo "ERROR: missing kind/ label" >&2
  exit 3
fi
if [ "$area_count" -lt 1 ]; then
  echo "ERROR: missing area/ label" >&2
  exit 3
fi
if [ "$pri_count" -ne 1 ]; then
  echo "ERROR: missing priority/ label" >&2
  exit 3
fi

# 5. Confidence threshold → force needs_human
conf=$(echo "$filtered" | jq -r .confidence)
if awk -v c="$conf" -v t="$threshold" 'BEGIN{exit !(c < t)}'; then
  filtered=$(echo "$filtered" | jq '.needs_human = true')
  echo "WARN: confidence $conf < $threshold; forcing needs_human=true" >&2
fi

echo "$filtered"
