#!/usr/bin/env bash
# Creates the isolated worktree codex will work in, and installs dependencies.
#
# Usage (from inside the target repo):
#   bash xlab-setup.sh --branch <name> --worktree <path> [--base origin/main] [--install "<cmd>"]
#
# --install overrides dependency install; default is picked from the lockfile
# (bun / pnpm / yarn / npm). --install none skips it.

set -euo pipefail

BRANCH=""
WORKTREE=""
BASE="origin/main"
INSTALL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)   BRANCH="$2";   shift 2 ;;
    --worktree) WORKTREE="$2"; shift 2 ;;
    --base)     BASE="$2";     shift 2 ;;
    --install)  INSTALL="$2";  shift 2 ;;
    *) echo "xlab-setup: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$BRANCH" ]]   || { echo "xlab-setup: missing --branch" >&2; exit 2; }
[[ -n "$WORKTREE" ]] || { echo "xlab-setup: missing --worktree" >&2; exit 2; }

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [[ -e "$WORKTREE" ]]; then
  echo "xlab-setup: path already exists: $WORKTREE" >&2
  echo "xlab-setup: check 'git worktree list' — another session may own this tree" >&2
  exit 2
fi

git fetch origin --quiet || echo "xlab-setup: fetch failed, using local $BASE" >&2
git worktree add -b "$BRANCH" "$WORKTREE" "$BASE"

cd "$WORKTREE"

if [[ -z "$INSTALL" ]]; then
  if   [[ -f bun.lock || -f bun.lockb ]];  then INSTALL="bun install --frozen-lockfile"
  elif [[ -f pnpm-lock.yaml ]];            then INSTALL="pnpm install --frozen-lockfile"
  elif [[ -f yarn.lock ]];                 then INSTALL="yarn install --frozen-lockfile"
  elif [[ -f package-lock.json ]];         then INSTALL="npm ci"
  else INSTALL="none"
  fi
fi

if [[ "$INSTALL" != "none" ]]; then
  echo "xlab-setup: $INSTALL"
  bash -c "$INSTALL" 2>&1 | tail -1
fi

echo "xlab-setup: OK — worktree: $WORKTREE (branch: $BRANCH, base: $BASE)"
