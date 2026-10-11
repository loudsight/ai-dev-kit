#!/usr/bin/env bash
# PreToolUse guard: refuses to read a large file whole (the Read tool with no offset or limit, or cat/less in Bash), so a bulk read
# does not eat the main context. The agent is told to narrow the read or to hand the question to a cheaper sub-agent.
# Needs jq. Fails open: any doubt lets the call through.
set -uo pipefail

# --- Tunables ----------------------------------------------------------------
THRESHOLD_LINES=400
# A path containing one of these is always let through whole.
EXEMPT_PATTERNS=(".claude/settings" ".claude/plans/")
# -------------------------------------------------------------------------------

command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat)
TOOL=$(jq -r '.tool_name // empty' <<<"$INPUT")

MESSAGE='Reading this whole file would use a large share of the context. Read with offset and limit, grep for the part you need, or hand the question to a sub-agent that returns only a summary.'

is_exempt() {
  for pattern in "${EXEMPT_PATTERNS[@]}"; do
    [[ "$1" == *"$pattern"* ]] && return 0
  done
  return 1
}

lines_in() {
  if [[ -f "$1" ]]; then wc -l <"$1" | tr -d ' '; else echo 0; fi
}

deny() {
  jq -n --arg reason "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

case "$TOOL" in
  Read)
    FILE=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")
    OFFSET=$(jq -r '.tool_input.offset // empty' <<<"$INPUT")
    LIMIT=$(jq -r '.tool_input.limit // empty' <<<"$INPUT")
    if [[ -n "$FILE" && -z "$OFFSET" && -z "$LIMIT" ]] && ! is_exempt "$FILE"; then
      COUNT=$(lines_in "$FILE")
      [[ "$COUNT" -gt "$THRESHOLD_LINES" ]] && deny "Blocked whole-file Read of $FILE ($COUNT lines, limit $THRESHOLD_LINES). $MESSAGE"
    fi
    ;;
  Bash)
    COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
    # A command that greps or ripgreps is already filtering.
    if [[ -n "$COMMAND" ]] && ! grep -qE '\b(grep|rg|ag)\b' <<<"$COMMAND" && grep -qE '\b(cat|less)\b' <<<"$COMMAND"; then
      for token in $COMMAND; do
        if [[ "$token" != -* && -f "$token" ]] && ! is_exempt "$token"; then
          COUNT=$(lines_in "$token")
          [[ "$COUNT" -gt "$THRESHOLD_LINES" ]] && deny "Blocked whole-file dump of $token ($COUNT lines, limit $THRESHOLD_LINES). $MESSAGE"
        fi
      done
    fi
    ;;
esac
exit 0
