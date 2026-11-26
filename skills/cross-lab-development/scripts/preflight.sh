#!/usr/bin/env bash
# Cross-lab preflight: prerequisites + roster in one call.
# Usage: bash "${CLAUDE_SKILL_DIR}/scripts/preflight.sh"
# Exit 0 = all present; 1 = something missing (details on stdout).

set -uo pipefail  # no -e: report EVERY gap, not the first one

HERE="$(cd "$(dirname "$0")" && pwd)"
MISSING=0

command -v codex >/dev/null || { echo "MISSING: codex CLI (npm i -g @openai/codex && codex login)"; MISSING=1; }
command -v jq    >/dev/null || { echo "MISSING: jq (needed by xlab-plan-review.sh)"; MISSING=1; }
command -v git   >/dev/null || { echo "MISSING: git"; MISSING=1; }

[ -f "$HOME/.codex/cross-lab.config.toml" ] \
  || { echo "MISSING: codex profile ~/.codex/cross-lab.config.toml (see README)"; MISSING=1; }

SP="$(bash "$HERE/superpowers-dir.sh" 2>/dev/null || true)"
echo "SP=$SP"
[ -n "$SP" ] || { echo "MISSING: superpowers plugin (/plugin install superpowers)"; MISSING=1; }

if [ -n "$SP" ]; then
  for f in "$SP/subagent-driven-development/scripts/task-brief" \
           "$SP/subagent-driven-development/scripts/review-package" \
           "$SP/subagent-driven-development/task-reviewer-prompt.md" \
           "$SP/requesting-code-review/code-reviewer.md"; do
    [ -e "$f" ] || { echo "MISSING: $f"; MISSING=1; }
  done
fi

ROSTER="$(bash "$HERE/roster-path.sh")"
if [ -f "$ROSTER" ]; then
  echo "== roster: $ROSTER"
  cat "$ROSTER"
else
  echo "WARN: no roster at $ROSTER — using SKILL.md defaults"
fi

exit "$MISSING"
