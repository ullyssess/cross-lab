#!/usr/bin/env bash
# Integrity snapshot of git config/hooks around a codex run.
#
# Codex needs write access to the gitdir to commit inside a linked worktree,
# which also opens a path to plant config/hooks that run OUTSIDE the sandbox.
# Snapshot BEFORE the run, compare AFTER; any difference = STOP.
#
# Usage:
#   bash xlab-gitmeta.sh --worktree <path> --out-dir <dir> --phase pre  [--tag T]
#   ...codex run...
#   bash xlab-gitmeta.sh --worktree <path> --out-dir <dir> --phase post [--tag T]
#
# Exit: 0 = clean, 1 = config/hooks changed (STOP), 2 = usage error.

set -euo pipefail

WORKTREE=""
OUT_DIR=""
PHASE=""
TAG="gitmeta"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree) WORKTREE="$2"; shift 2 ;;
    --out-dir)  OUT_DIR="$2";  shift 2 ;;
    --phase)    PHASE="$2";    shift 2 ;;
    --tag)      TAG="$2";      shift 2 ;;
    *) echo "xlab-gitmeta: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$WORKTREE" ]] || { echo "xlab-gitmeta: missing --worktree" >&2; exit 2; }
[[ -n "$OUT_DIR" ]]  || { echo "xlab-gitmeta: missing --out-dir" >&2; exit 2; }
[[ "$PHASE" == "pre" || "$PHASE" == "post" ]] || {
  echo "xlab-gitmeta: --phase must be 'pre' or 'post'" >&2; exit 2; }
[[ -d "$WORKTREE" ]] || { echo "xlab-gitmeta: worktree does not exist: $WORKTREE" >&2; exit 2; }

mkdir -p "$OUT_DIR"

GITDIR="$(git -C "$WORKTREE" rev-parse --absolute-git-dir)"
COMMON="$(git -C "$WORKTREE" rev-parse --path-format=absolute --git-common-dir)"

PRE="$OUT_DIR/$TAG.pre"
POST="$OUT_DIR/$TAG.post"
SNAPSHOT="$OUT_DIR/$TAG.$PHASE"

# `|| true`: config.worktree often does not exist and an empty hooks/ breaks
# the glob; without it `set -e` kills the script inside the group.
{
  git -C "$WORKTREE" config --list --show-origin
  cat "$GITDIR/config.worktree" 2>/dev/null || true
  shasum "$COMMON"/hooks/* 2>/dev/null || true
} > "$SNAPSHOT"

if [[ "$PHASE" == "pre" ]]; then
  echo "GITMETA: pre snapshot saved ($SNAPSHOT)"
  exit 0
fi

if [[ ! -f "$PRE" ]]; then
  echo "GITMETA: NO pre snapshot ($PRE) — nothing to compare against" >&2
  exit 2
fi

if diff -q "$PRE" "$POST" >/dev/null; then
  echo "GITMETA: CLEAN (no config/hooks changes)"
  exit 0
fi

echo "GITMETA: CHANGED — STOP"
diff "$PRE" "$POST" || true
exit 1
