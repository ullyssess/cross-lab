#!/usr/bin/env bash
# Assembles the codex brief for one task: superpowers task-brief output +
# implementer contract + optional controller context, appended verbatim.
# All $(...), redirects and globbing live here, behind one script call,
# so the controller's Bash call stays a simple, allowlistable command.
#
# Usage: assemble-brief.sh PLAN TASK_NUM SCRATCH_DIR [CONTEXT_FILE]
# Prints the assembled brief path.
set -euo pipefail

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
  echo "usage: assemble-brief.sh PLAN TASK_NUM SCRATCH_DIR [CONTEXT_FILE]" >&2
  exit 2
fi

plan=$1; n=$2; scratch=$3; ctx=${4:-}
HERE="$(cd "$(dirname "$0")" && pwd)"

[ -f "$plan" ]    || { echo "no such plan: $plan" >&2; exit 2; }
[ -d "$scratch" ] || { echo "no such scratch dir: $scratch" >&2; exit 2; }

SP="$(bash "$HERE/superpowers-dir.sh")" || { echo "superpowers plugin not found" >&2; exit 2; }
task_brief="$SP/subagent-driven-development/scripts/task-brief"
[ -x "$task_brief" ] || { echo "task-brief not found: $task_brief" >&2; exit 2; }

template="$HERE/../codex-brief-template.md"
[ -f "$template" ] || { echo "no template: $template" >&2; exit 2; }

brief_path="$scratch/task-${n}-brief.md"
"$task_brief" "$plan" "$n" "$brief_path" >/dev/null
[ -s "$brief_path" ] || { echo "brief not written: $brief_path" >&2; exit 3; }

out="$scratch/task-${n}-codex-brief.md"
cat "$brief_path" "$template" > "$out"

if [ -n "$ctx" ]; then
  [ -f "$ctx" ] || { echo "no such context file: $ctx" >&2; exit 2; }
  printf '\n' >> "$out"
  cat "$ctx" >> "$out"
fi

echo "$out"
