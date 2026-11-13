#!/usr/bin/env bash
# Runs everything hand-authored in this package:
#   - `make test` — the conformance harness against the shared corpus
#   - `make unit` — every standalone unit test under tests/ (no corpus needed)
# `run_conformance.sh` runs only the first of those; this is the full run.
#
# Exit 0 == all green. Both halves run even when the first fails, so one
# invocation reports the full picture rather than only the first breakage.
set -uo pipefail
cd "$(dirname "$0")"

# testkit (`testkit :baseline` / `:test`) sets TESTKIT_REPORT: every test below
# then adds one result line to that file (tom_test_kit's line protocol, one
# JSON object per line). tk_result also folds the test's exit code into rc.
tk_result() { # <test name> <exit code>
  if [ -n "${TESTKIT_REPORT:-}" ]; then
    local result=ok
    [ "$2" -eq 0 ] || result=fail
    printf '{"test":"%s","result":"%s"}\n' "$1" "$result" >>"$TESTKIT_REPORT"
  fi
  [ "$2" -eq 0 ] || rc=1
}

CORPUS="${1:-../tom_som_conformance/corpus}"

rc=0
echo "== conformance harness =="
make --no-print-directory test CORPUS="$CORPUS"
tk_result "tests/conformance.c" $?

echo "== unit tests =="
# Each unit binary runs on its own (what `make unit` runs), so each
# has its own result.
if make --no-print-directory unit-bins; then
  for t in $(make --no-print-directory -s unit-list); do
    echo "== $t =="
    "./$t"
    tk_result "tests/${t#build/}.c" $?
  done
else
  tk_result "unit tests (build)" 1
fi

if [ "$rc" -eq 0 ]; then
  echo "All C runtime tests passed."
fi
exit "$rc"
