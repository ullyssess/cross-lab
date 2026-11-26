#!/usr/bin/env bash
# Dispatches codex on one cross-lab task (or resumes it with findings).
#
# Computes the sandbox writable_roots for a linked worktree, pins network
# access, and filters the output. Run it with run_in_background: true.
#
# Usage:
#   bash xlab-dispatch.sh \
#     --worktree <path> --brief <file.md> --out <file.txt> \
#     --model <openai-model> [--effort high] [--network false] [--resume SESSION_ID]
#
# Full codex transcript: <out>.log. Proof of a real start: `session id:` in it.

set -euo pipefail

WORKTREE=""
BRIEF=""
OUT=""
MODEL=""
EFFORT="high"
NETWORK="false"
RESUME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree) WORKTREE="$2"; shift 2 ;;
    --brief)    BRIEF="$2";    shift 2 ;;
    --out)      OUT="$2";      shift 2 ;;
    --model)    MODEL="$2";    shift 2 ;;
    --effort)   EFFORT="$2";   shift 2 ;;
    --network)  NETWORK="$2";  shift 2 ;;
    --resume)   RESUME="$2";   shift 2 ;;
    *) echo "xlab-dispatch: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$WORKTREE" ]] || { echo "xlab-dispatch: missing --worktree" >&2; exit 2; }
[[ -n "$BRIEF" ]]    || { echo "xlab-dispatch: missing --brief" >&2; exit 2; }
[[ -n "$OUT" ]]      || { echo "xlab-dispatch: missing --out" >&2; exit 2; }
[[ -n "$MODEL" ]]    || { echo "xlab-dispatch: missing --model (take it from the roster)" >&2; exit 2; }
[[ -d "$WORKTREE" ]] || { echo "xlab-dispatch: worktree does not exist: $WORKTREE" >&2; exit 2; }
[[ -f "$BRIEF" ]]    || { echo "xlab-dispatch: brief does not exist: $BRIEF" >&2; exit 2; }

mkdir -p "$(dirname "$OUT")"

# A linked worktree keeps its gitdir inside the main repo — without these
# roots `git commit` fails in the sandbox. Only objects/refs/logs of the
# common dir, NEVER its root: config and hooks there execute code outside
# the sandbox on the controller's next git command.
GITDIR="$(git -C "$WORKTREE" rev-parse --absolute-git-dir)"
COMMON="$(git -C "$WORKTREE" rev-parse --path-format=absolute --git-common-dir)"
ROOTS="[\"$GITDIR\",\"$COMMON/objects\",\"$COMMON/refs\",\"$COMMON/logs\"]"

cd "$WORKTREE"

args=(--profile cross-lab exec)

# `resume <SESSION_ID>` must follow `exec` directly, before the flags.
# `exec resume` rejects `--sandbox` ("unexpected argument"), so the sandbox
# goes through `-c sandbox_mode=...` there (same writable_roots).
if [[ -n "$RESUME" ]]; then
  args+=(resume "$RESUME" -c 'sandbox_mode="workspace-write"')
else
  args+=(--sandbox workspace-write)
fi

args+=(
  -m "$MODEL"
  -c "sandbox_workspace_write.writable_roots=$ROOTS"
  -c "sandbox_workspace_write.network_access=$NETWORK"
  -c "model_reasoning_effort=\"$EFFORT\""
  -o "$OUT"
  -
)

# Full output to a file; the filter reads the file, not the stream —
# `codex | grep | head` under pipefail ended in SIGPIPE (exit 141) on success.
codex "${args[@]}" < "$BRIEF" > "$OUT.log" 2>&1
grep -iE "session id|error|^\[|codex$" "$OUT.log" | head -20 || true
