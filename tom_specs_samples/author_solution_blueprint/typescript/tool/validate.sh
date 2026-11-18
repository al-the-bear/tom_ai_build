#!/usr/bin/env bash
# Records — and re-checks — the compile-time failure this port shows: a section
# of the wrong type, assigned or passed where another belongs, does not
# compile. `type-errors/miswritten_section.ts` holds three such mistakes; this
# script type-checks it (`tsc -p tsconfig.type-errors.json`) and passes only
# while `tsc` REJECTS it with exactly the errors recorded in
# `type-errors/expected_tsc_output.txt`.
#
# Why a script and not part of `npm start`. The sample's stdout is what
# `tool/run_all_samples.sh` diffs against the Dart sample's expected output,
# and a program that does not compile cannot be part of a program that runs.
# So the compiler's verdict is RECORDED, and this script keeps the record
# honest: a facade change that made the mistake compile — or changed what the
# compiler says about it — fails here.
#
# Semantics, the same as tool/run_all_samples.sh: a missing toolchain SKIPs
# with the reason stated and never passes silently; --strict makes a skip a
# failure. Pass --record to overwrite the recorded output instead of comparing.
#
# Usage:  ./tool/validate.sh [--record] [--strict]
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PORT="$(dirname "$HERE")"
RECORD_FILE="$PORT/type-errors/expected_tsc_output.txt"

RECORD=0
STRICT=0
for arg in "$@"; do
  case "$arg" in
    --record) RECORD=1 ;;
    --strict) STRICT=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

skip() {
  echo "  SKIP     $1"
  [ "$STRICT" -eq 1 ] && { echo "--strict: a skip is a failure."; exit 1; }
  exit 0
}

TSC="$PORT/node_modules/.bin/tsc"
[ -x "$TSC" ] || skip "tsc not installed in this port (run npm install)"
[ -d "$PORT/../../../tom_som_typescript_v0/dist" ] \
  || skip "tom_som_typescript_v0 is not built (run npm run build)"

got="$(cd "$PORT" && "$TSC" -p tsconfig.type-errors.json --pretty false 2>&1)"
status=$?
if [ "$status" -eq 0 ]; then
  echo "  FAIL     type-errors/miswritten_section.ts compiled — the facade no"
  echo "           longer rejects a section of the wrong type"
  exit 1
fi

if [ "$RECORD" -eq 1 ]; then
  printf '%s\n' "$got" > "$RECORD_FILE"
  echo "  RECORDED type-errors/expected_tsc_output.txt"
  exit 0
fi

if [ "$got" = "$(cat "$RECORD_FILE")" ]; then
  echo "  PASS     the miswritten section still fails to compile, as recorded"
  exit 0
fi
echo "  FAIL     tsc's errors differ from type-errors/expected_tsc_output.txt:"
diff <(printf '%s\n' "$got") "$RECORD_FILE" | head -n 20 | sed 's/^/           /'
exit 1
