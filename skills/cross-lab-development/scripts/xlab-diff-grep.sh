#!/usr/bin/env bash
# Greps a worktree's diff (reviewer spot checks: `any`, console.log, ...).
#
# The pattern goes through grep -E (full ERE with \b) — NOT awk or git -G:
# macOS awk does not know \b and would silently return zero hits.
#
# Usage:
#   bash xlab-diff-grep.sh --worktree <path> --range <A..B> --pattern <ERE> [--all]
#
# By default searches ADDED lines only (^+); --all takes the whole diff.

set -euo pipefail

WORKTREE=""
RANGE=""
PATTERN=""
ALL="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree) WORKTREE="$2"; shift 2 ;;
    --range)    RANGE="$2";    shift 2 ;;
    --pattern)  PATTERN="$2";  shift 2 ;;
    --all)      ALL="true";    shift 1 ;;
    *) echo "xlab-diff-grep: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$WORKTREE" ]] || { echo "xlab-diff-grep: missing --worktree" >&2; exit 2; }
[[ -n "$RANGE" ]]    || { echo "xlab-diff-grep: missing --range" >&2; exit 2; }
[[ -n "$PATTERN" ]]  || { echo "xlab-diff-grep: missing --pattern" >&2; exit 2; }
[[ -d "$WORKTREE" ]] || { echo "xlab-diff-grep: worktree does not exist: $WORKTREE" >&2; exit 2; }

TOTAL=0
while IFS= read -r FILE; do
  SCOPE="$(git -C "$WORKTREE" diff "$RANGE" -- "$FILE")"
  if [[ "$ALL" != "true" ]]; then
    SCOPE="$(printf '%s\n' "$SCOPE" | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
  fi
  MATCHES="$(printf '%s\n' "$SCOPE" | grep -E -- "$PATTERN" || true)"
  if [[ -n "$MATCHES" ]]; then
    echo "== $FILE"
    printf '%s\n' "$MATCHES"
    TOTAL=$((TOTAL + $(printf '%s\n' "$MATCHES" | wc -l | tr -d ' ')))
  fi
done < <(git -C "$WORKTREE" diff --name-only "$RANGE")

if [[ "$TOTAL" -eq 0 ]]; then
  echo "xlab-diff-grep: 0 hits for /$PATTERN/ in $RANGE"
else
  echo "== total: $TOTAL hits"
fi
