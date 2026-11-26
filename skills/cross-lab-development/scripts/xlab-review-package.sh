#!/usr/bin/env bash
# Builds the superpowers review package for BASE..HEAD of a worktree.
#
# Usage:
#   bash xlab-review-package.sh --worktree <path> --base <SHA> [--head HEAD]
#
# Prints the package path (like the underlying superpowers script).

set -euo pipefail

WORKTREE=""
BASE=""
HEAD_REF="HEAD"
HERE="$(cd "$(dirname "$0")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree) WORKTREE="$2"; shift 2 ;;
    --base)     BASE="$2";     shift 2 ;;
    --head)     HEAD_REF="$2"; shift 2 ;;
    *) echo "xlab-review-package: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$WORKTREE" ]] || { echo "xlab-review-package: missing --worktree" >&2; exit 2; }
[[ -n "$BASE" ]]     || { echo "xlab-review-package: missing --base" >&2; exit 2; }
[[ -d "$WORKTREE" ]] || { echo "xlab-review-package: worktree does not exist: $WORKTREE" >&2; exit 2; }

SP="$(bash "$HERE/superpowers-dir.sh")" || { echo "xlab-review-package: superpowers plugin not found" >&2; exit 2; }
RP="$SP/subagent-driven-development/scripts/review-package"
[[ -x "$RP" ]] || { echo "xlab-review-package: missing $RP" >&2; exit 2; }

cd "$WORKTREE"
exec "$RP" "$BASE" "$HEAD_REF"
