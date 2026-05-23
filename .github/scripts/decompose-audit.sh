#!/usr/bin/env bash
# decompose-audit.sh EVENT REPO ISSUE [extras...]
#
# EVENT=propose: extras = AGENT OUTCOME PROPOSAL_SHA
#   stdin: validated decomposition JSON (for child_count)
#
# EVENT=approve: extras = ACTOR AUTHOR_ASSOCIATION OUTCOME PROPOSAL_SHA
#   stdin: applied-state JSON (for children_filed)
#
# appends one JSONL line to decompose-audit.jsonl

set -euo pipefail

event="$1"; repo="$2"; issue="$3"
chronon="$(python3 -c "from datetime import datetime, timezone; n=datetime.now(timezone.utc); print(n.strftime('%Y-%m-%dT%H:%M:%S.') + f'{n.microsecond//1000:03d}Z')")"
input=$(cat || echo '{}')

case "$event" in
  propose)
    agent="$4"; outcome="$5"; proposal_sha="$6"
    child_count=$(echo "$input" | jq '.children | length // 0')
    line=$(jq -nc \
      --arg chronon "$chronon" --arg repo "$repo" --arg agent "$agent" \
      --arg outcome "$outcome" --arg sha "$proposal_sha" \
      --argjson issue "$issue" --argjson child_count "$child_count" \
      '{chronon:$chronon, event:"propose", repo:$repo, issue:$issue, agent:$agent, outcome:$outcome, child_count:$child_count, proposal_sha:$sha}')
    ;;
  approve)
    actor="$4"; assoc="$5"; outcome="$6"; proposal_sha="$7"
    children_filed=$(echo "$input" | jq '.children_filed // []')
    line=$(jq -nc \
      --arg chronon "$chronon" --arg repo "$repo" --arg actor "$actor" \
      --arg assoc "$assoc" --arg outcome "$outcome" --arg sha "$proposal_sha" \
      --argjson issue "$issue" --argjson filed "$children_filed" \
      '{chronon:$chronon, event:"approve", repo:$repo, issue:$issue, actor:$actor, author_association:$assoc, outcome:$outcome, children_filed:$filed, proposal_sha:$sha}')
    ;;
  *)
    echo "ERROR: unknown event '$event' (expected propose|approve)" >&2
    exit 2
    ;;
esac

echo "$line" >> decompose-audit.jsonl
