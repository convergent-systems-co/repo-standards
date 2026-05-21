#!/usr/bin/env bash
# triage-redact.sh — read issue body on stdin, emit redacted body on stdout.
# Replaces common secret-shaped tokens with [REDACTED:<kind>] before sending
# the body to the agent. Per Common.md §4.5.

set -euo pipefail

sed -E \
  -e 's/sk-[A-Za-z0-9_-]{20,}/[REDACTED:openai-key]/g' \
  -e 's/ghp_[A-Za-z0-9]{36}/[REDACTED:github-pat]/g' \
  -e 's/gho_[A-Za-z0-9]{36}/[REDACTED:github-oauth]/g' \
  -e 's/AKIA[0-9A-Z]{16}/[REDACTED:aws-access-key]/g' \
  -e 's/(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]+/\1=[REDACTED:credential]/gI' \
  -e 's/-----BEGIN [A-Z ]*PRIVATE KEY-----/[REDACTED:private-key-block]/g'
