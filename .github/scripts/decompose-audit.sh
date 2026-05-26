#!/usr/bin/env bash
# decompose-audit.sh EVENT REPO ISSUE [extras...]
#
# EVENT=propose: extras = AGENT OUTCOME PROPOSAL_SHA [BODY_SHA [RUN_ID]]
#   stdin: validated decomposition JSON (for child_count)
#   body_sha: SHA of the redacted proposal body (optional, default "")
#   run_id:   GH workflow run ID (optional, default "")
#
# EVENT=approve: extras = ACTOR AUTHOR_ASSOCIATION OUTCOME PROPOSAL_SHA [RUN_ID]
#   stdin: applied-state JSON (for children_filed)
#   run_id:   GH workflow run ID (optional, default "")
#
# appends one JSONL line to decompose-audit.jsonl

set -euo pipefail

event="$1"; repo="$2"; issue="$3"
chronon="$(python3 -c "from datetime import datetime, timezone; n=datetime.now(timezone.utc); print(n.strftime('%Y-%m-%dT%H:%M:%S.') + f'{n.microsecond//1000:03d}Z')")"
input=$(cat || echo '{}')

case "$event" in
  propose)
    agent="$4"; outcome="$5"; proposal_sha="$6"
    body_sha="${7:-}"; run_id="${8:-}"
    child_count=$(echo "$input" | jq '.children | length // 0')
    line=$(jq -nc \
      --arg chronon "$chronon" --arg repo "$repo" --arg agent "$agent" \
      --arg outcome "$outcome" --arg sha "$proposal_sha" \
      --arg body_sha "$body_sha" --arg run_id "$run_id" \
      --argjson issue "$issue" --argjson child_count "$child_count" \
      '{chronon:$chronon, event:"propose", repo:$repo, issue:$issue, agent:$agent, outcome:$outcome, child_count:$child_count, proposal_sha:$sha, body_sha:$body_sha, run_id:$run_id}')
    ;;
  approve)
    actor="$4"; assoc="$5"; outcome="$6"; proposal_sha="$7"
    run_id="${8:-}"
    children_filed=$(echo "$input" | jq '.children_filed // []')
    line=$(jq -nc \
      --arg chronon "$chronon" --arg repo "$repo" --arg actor "$actor" \
      --arg assoc "$assoc" --arg outcome "$outcome" --arg sha "$proposal_sha" \
      --arg run_id "$run_id" \
      --argjson issue "$issue" --argjson filed "$children_filed" \
      '{chronon:$chronon, event:"approve", repo:$repo, issue:$issue, actor:$actor, author_association:$assoc, outcome:$outcome, children_filed:$filed, proposal_sha:$sha, run_id:$run_id}')
    ;;
  *)
    echo "ERROR: unknown event '$event' (expected propose|approve)" >&2
    exit 2
    ;;
esac

echo "$line" >> decompose-audit.jsonl
