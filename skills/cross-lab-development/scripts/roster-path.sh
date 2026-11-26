#!/usr/bin/env bash
# Prints the path of the effective model roster.
#   1. $XLAB_ROSTER, when set
#   2. ~/.claude/cross-lab/models.toml — the user's own copy (set-model writes here)
#   3. models.toml bundled with the skill — defaults, overwritten on plugin update
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
USER_ROSTER="$HOME/.claude/cross-lab/models.toml"

if [ -n "${XLAB_ROSTER:-}" ]; then
  printf '%s\n' "$XLAB_ROSTER"
elif [ -f "$USER_ROSTER" ]; then
  printf '%s\n' "$USER_ROSTER"
else
  printf '%s\n' "$SKILL_DIR/models.toml"
fi
