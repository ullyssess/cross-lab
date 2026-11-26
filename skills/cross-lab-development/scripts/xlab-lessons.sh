#!/usr/bin/env bash
# Lessons registry for cross-lab-development (optional, per repo).
#   --list   dump all entries to stdout (input for brief selection)
#   --check  validate entry format (exit 1 on any violation)
#
# Usage: xlab-lessons.sh --list|--check [--dir DIR]
# Run from the repo root: --dir and `reference` resolve against cwd.
# Format: see "Lessons registry" in the plugin README.
set -euo pipefail

mode=""
dir="docs/lessons"

while [ $# -gt 0 ]; do
  case "$1" in
    --list)  mode=list; shift ;;
    --check) mode=check; shift ;;
    --dir)   dir=${2:-}; [ -n "$dir" ] || { echo "--dir needs a value" >&2; exit 2; }; shift 2 ;;
    *) echo "usage: xlab-lessons.sh --list|--check [--dir DIR]" >&2; exit 2 ;;
  esac
done

[ -n "$mode" ] || { echo "usage: xlab-lessons.sh --list|--check [--dir DIR]" >&2; exit 2; }

# No registry is not an error: most repos will not have one.
if [ ! -d "$dir" ]; then
  exit 0
fi

shopt -s nullglob
files=("$dir"/*.md)
shopt -u nullglob

allowed_severity="blocker trap quality"
rc=0

field() {
  # field FILE NAME — frontmatter value from the first 10 lines
  sed -n "1,10{s/^$2:[[:space:]]*//p;}" "$1" | head -n1
}

for f in "${files[@]}"; do
  base=$(basename "$f" .md)
  [ "$base" = "README" ] && continue

  id=$(field "$f" id)
  trigger=$(field "$f" trigger)
  severity=$(field "$f" severity)
  reference_line=$(sed -n '1,10{/^reference:/p;}' "$f" | head -n1)
  reference=$(field "$f" reference)
  severity=${severity%%#*}
  severity=$(printf '%s' "$severity" | tr -d '[:space:]')
  # body = everything after the second ---
  body=$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; next} n>=2' "$f")
  body_lines=$(printf '%s\n' "$body" | grep -c '[^[:space:]]' || true)

  if [ "$mode" = check ]; then
    [ -n "$id" ]       || { echo "$f: missing id" >&2; rc=1; }
    [ -n "$trigger" ]  || { echo "$f: missing trigger" >&2; rc=1; }
    [ -n "$severity" ] || { echo "$f: missing severity" >&2; rc=1; }
    if [ -n "$reference_line" ]; then
      checked_reference=${reference%%#*}
      checked_reference=$(printf '%s' "$checked_reference" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
      if [ -z "$checked_reference" ]; then
        echo "$f: reference is empty" >&2
        rc=1
      else
        case "$checked_reference" in
          /*)
            echo "$f: reference '$checked_reference' must be relative to the repo root" >&2
            rc=1
            ;;
          *)
            case "/$checked_reference/" in
              */../*)
                echo "$f: reference '$checked_reference' contains a forbidden '..' segment" >&2
                rc=1
                ;;
              *)
                if [ ! -f "$checked_reference" ]; then
                  echo "$f: reference '$checked_reference' does not exist" >&2
                  rc=1
                elif ! printf '%s\n' "$body" | grep -Fq -- "$checked_reference"; then
                  echo "$f: reference '$checked_reference' does not appear in the body" >&2
                  rc=1
                fi
                ;;
            esac
            ;;
        esac
      fi
    fi
    [ "$id" = "$base" ] || { echo "$f: id '$id' != file name '$base'" >&2; rc=1; }
    case " $allowed_severity " in
      *" $severity "*) ;;
      *) echo "$f: severity '$severity' not in {blocker,trap,quality}" >&2; rc=1 ;;
    esac
    [ "$body_lines" -ge 1 ] || { echo "$f: empty body" >&2; rc=1; }
    [ "$body_lines" -le 8 ] || { echo "$f: body has $body_lines lines (max 8)" >&2; rc=1; }
  else
    printf '### %s [%s] trigger: %s\n' "$id" "$severity" "$trigger"
    [ -z "$reference" ] || printf 'reference: %s\n' "$reference"
    printf '%s\n\n' "$body"
  fi
done

exit $rc
