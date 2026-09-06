#!/usr/bin/env bash
# Records — and re-checks — the two reports this walkthrough prints but cannot
# produce itself: Phase 4's `validate_codespecs` run over the emitted trio, and
# Phase 6's `dart test` + `dart analyze` + `dart format`.
#
# Why a script and not part of `dart run`. `tom_specs_clitool` is a development
# tool, not a dependency of the emitted code, so it is deliberately absent from
# this sample's pubspec. And shelling out to `dart test` from the sample itself
# would make the sample's stdout depend on the host's test runner, while
# `tool/run_all_samples.sh` diffs that stdout. So both reports are RECORDED —
# `codespec/validation_report.txt` and `spec/06_implementation_report.txt` —
# and this script is what keeps the records honest.
#
# The Phase-4 validator runs TWICE, and the difference is the lesson: without
# `--extracts`, checks 35 and 36 announce themselves unrun; with it they run,
# and they are the two that decide the §9.6 self-sufficiency property.
#
# Semantics, the same as tool/run_all_samples.sh: a missing toolchain SKIPs
# with the reason stated and never passes silently; --strict makes a skip a
# failure. Pass --record to overwrite the records instead of comparing.
#
# Usage:  ./tool/validate.sh [--record] [--strict]
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SAMPLE="$(dirname "$HERE")"
CLITOOL="$(cd "$SAMPLE/../../tom_specs_clitool" 2>/dev/null && pwd || true)"
CS_REPORT="$SAMPLE/codespec/validation_report.txt"
IMPL_REPORT="$SAMPLE/spec/06_implementation_report.txt"

RECORD=0
STRICT=0
for arg in "$@"; do
  case "$arg" in
    --record) RECORD=1 ;;
    --strict) STRICT=1 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
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

# The extracts are Phase 4's own input; produce them before validating against
# a stale tree.
#
# Under --record the walkthrough's own exit status is IGNORED, and that is not
# laziness. The walkthrough stops at the first failing gate — PF-FLW-OVE's
# "every gate can fail" only means anything if failing one stops the run — and
# gate G4 reads the very report this invocation is about to write. So on a
# first record, or after a deliberate change to the trio, the run legitimately
# fails at G4 while still having produced the extracts G4 needs. When
# COMPARING, the records exist and the run must succeed.
( cd "$SAMPLE" && dart pub get > /dev/null && dart run > /dev/null 2>&1 )
RUN_RC=$?
if [ "$RECORD" -eq 0 ] && [ "$RUN_RC" -ne 0 ]; then
  echo "  FAIL     the walkthrough itself did not run (a gate failed)"
  ( cd "$SAMPLE" && dart run 2>&1 | tail -n 12 | sed 's/^/           /' )
  exit 1
fi

run_validator() {
  ( cd "$CLITOOL" && dart run bin/validate_codespecs.dart \
      --shared "$SAMPLE/codespec/shared" \
      --client "$SAMPLE/codespec/client" \
      --server "$SAMPLE/codespec/server" \
      "$@" 2>&1 )
}

CS_ACTUAL="$(
  echo "\$ validate_codespecs --shared codespec/shared --client codespec/client \\"
  echo "                      --server codespec/server"
  run_validator | sed 's/^/  /'
  echo
  echo "\$ validate_codespecs --shared codespec/shared --client codespec/client \\"
  echo "                      --server codespec/server \\"
  echo "                      --extracts build/codespecs_extracts"
  run_validator --extracts "$SAMPLE/build/codespecs_extracts" | sed 's/^/  /'
)"

IMPL_ACTUAL="$(
  cd "$SAMPLE"
  echo '$ dart test'
  # `--reporter compact` redraws one line with carriage returns, so `tail` on
  # the raw stream returns the whole run. Split on CR first, then take the last
  # non-empty line — which is the summary.
  dart test --reporter compact 2>&1 | tr '\r' '\n' \
    | sed 's/[[:space:]]*$//' | grep -v '^$' | tail -n 1 \
    | sed 's/^[0-9:]* *//;s/^/  /'
  echo
  echo '$ dart analyze'
  dart analyze 2>&1 | tail -n 1 | sed 's/^/  /'
  echo
  echo '$ dart format --output=none --set-exit-if-changed .'
  if dart format --output=none --set-exit-if-changed . > /dev/null 2>&1; then
    echo '  all files already formatted'
  else
    echo '  FORMATTING DEVIATIONS'
  fi
)"

write_or_compare() {
  local actual="$1" path="$2" label="$3"
  if [ "$RECORD" -eq 1 ]; then
    printf '%s\n' "$actual" > "$path"
    echo "  RECORDED $label"
    return 0
  fi
  if printf '%s\n' "$actual" | diff -u "$path" - > /dev/null 2>&1; then
    echo "  PASS     $label still matches"
    return 0
  fi
  echo "  FAIL     $label is stale"
  printf '%s\n' "$actual" | diff -u "$path" - | head -n 30 | sed 's/^/           /'
  return 1
}

RC=0
write_or_compare "$CS_ACTUAL" "$CS_REPORT" "codespec/validation_report.txt" || RC=1
write_or_compare "$IMPL_ACTUAL" "$IMPL_REPORT" \
  "spec/06_implementation_report.txt" || RC=1
exit $RC
