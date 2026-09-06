#!/usr/bin/env bash
# Records — and re-checks — stage 4 of this sample: `validate_codespecs.dart`
# run over the emitted shared/client/server trio, twice.
#
# Why a script and not part of `dart run`. `tom_specs_clitool` is a development
# tool, not a dependency of the emitted code, so it is deliberately absent from
# this sample's pubspec (see the README). Shelling out to it from the sample
# itself would make the sample's stdout depend on whether the workspace happens
# to sit beside it, and `tool/run_all_samples.sh` diffs that stdout. So the
# validator's output is RECORDED in codespec/validation_report.txt, and this
# script is what keeps the record honest.
#
# Two invocations, because the difference between them is the lesson: without
# --extracts six checks announce themselves unrun; with it they run.
#
# Semantics, the same as tool/run_all_samples.sh: a missing toolchain SKIPs
# with the reason stated and never passes silently; --strict makes a skip a
# failure. Pass --record to overwrite the recorded report instead of comparing.
#
# Usage:  ./tool/validate.sh [--record] [--strict]
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SAMPLE="$(dirname "$HERE")"
CLITOOL="$(cd "$SAMPLE/../../tom_specs_clitool" 2>/dev/null && pwd || true)"
REPORT="$SAMPLE/codespec/validation_report.txt"

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

command -v dart > /dev/null 2>&1 || skip "dart not on PATH"
[ -n "$CLITOOL" ] && [ -f "$CLITOOL/bin/validate_codespecs.dart" ] \
  || skip "tom_specs_clitool not beside this sample — it is a development tool, not a dependency"

# The extracts are stage 2's output; without a run there is nothing to validate
# against, so produce them first rather than validating a stale tree.
( cd "$SAMPLE" && dart pub get > /dev/null && dart run > /dev/null ) \
  || { echo "  FAIL     the sample itself did not run"; exit 1; }

run_validator() {
  ( cd "$CLITOOL" && dart run bin/validate_codespecs.dart \
      --shared "$SAMPLE/codespec/shared" \
      --client "$SAMPLE/codespec/client" \
      --server "$SAMPLE/codespec/server" \
      "$@" 2>&1 )
}

ACTUAL="$(
  echo "\$ validate_codespecs --shared codespec/shared --client codespec/client \\"
  echo "                      --server codespec/server"
  run_validator | sed 's/^/  /'
  echo
  echo "\$ validate_codespecs --shared codespec/shared --client codespec/client \\"
  echo "                      --server codespec/server \\"
  echo "                      --extracts build/codespecs_extracts"
  run_validator --extracts "$SAMPLE/build/codespecs_extracts" | sed 's/^/  /'
)"

if [ "$RECORD" -eq 1 ]; then
  printf '%s\n' "$ACTUAL" > "$REPORT"
  echo "  RECORDED $REPORT"
  exit 0
fi

if printf '%s\n' "$ACTUAL" | diff -u "$REPORT" - > /dev/null 2>&1; then
  echo "  PASS     the recorded validation report still matches"
  exit 0
fi

echo "  FAIL     codespec/validation_report.txt is stale"
printf '%s\n' "$ACTUAL" | diff -u "$REPORT" - | head -n 40 | sed 's/^/           /'
exit 1
