#!/usr/bin/env bash
# Progress ledger of a worktree (read / append), stored in the gitdir so it
# never shows up in the diff.
#
# Usage:
#   bash xlab-ledger.sh --worktree <path>                  # print ledger
#   bash xlab-ledger.sh --worktree <path> --append "entry" # append + print

set -euo pipefail

WORKTREE=""
APPEND=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree) WORKTREE="$2"; shift 2 ;;
    --append)   APPEND="$2";   shift 2 ;;
    *) echo "xlab-ledger: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$WORKTREE" ]] || { echo "xlab-ledger: missing --worktree" >&2; exit 2; }
[[ -d "$WORKTREE" ]] || { echo "xlab-ledger: worktree does not exist: $WORKTREE" >&2; exit 2; }

SDD="$(git -C "$WORKTREE" rev-parse --path-format=absolute --git-path sdd)"
LEDGER="$SDD/progress.md"

if [[ -n "$APPEND" ]]; then
  mkdir -p "$SDD"
  printf '%s\n' "$APPEND" >> "$LEDGER"
fi

if [[ -f "$LEDGER" ]]; then
  cat "$LEDGER"
else
  echo "xlab-ledger: no ledger yet ($LEDGER)"
fi
