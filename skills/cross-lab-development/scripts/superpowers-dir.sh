#!/usr/bin/env bash
# Prints the skills/ directory of the newest installed superpowers plugin,
# whichever marketplace it came from. Empty output + exit 1 = not installed.
set -euo pipefail

# Sort on the version path segment, not the whole path: two marketplaces
# would otherwise sort by marketplace name instead of version.
dir="$(ls -d "$HOME"/.claude/plugins/cache/*/superpowers/*/skills 2>/dev/null \
  | awk -F/ '{ print $(NF-1) "\t" $0 }' | sort -V | tail -n1 | cut -f2)"

[ -n "$dir" ] || exit 1
printf '%s\n' "$dir"
