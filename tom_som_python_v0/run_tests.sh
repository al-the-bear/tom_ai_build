#!/usr/bin/env bash
# Runs everything hand-authored in this generated tree:
#   - the behavioural test        (tests/som_v0_generated_test.py)
#   - the metadata agreement test (tests/som_v0_meta_test.py)
#   - the three samples           (examples/a_typed_access.py, b_, c_)
# against the generic runtime resolved through PYTHONPATH.
#
# Mirrors the C / C++ v0 runners: exit 0 == all green. Run from anywhere; it
# cd's to its own directory so the relative RUNTIME_DIR and the meta-data
# default path used by sample (c) resolve.
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

RUNTIME_DIR="${RUNTIME_DIR:-../tom_som_python_runtime}"
export PYTHONPATH="$PWD:$RUNTIME_DIR${PYTHONPATH:+:$PYTHONPATH}"
PY="${PYTHON:-python3}"

rc=0
for t in tests/*.py; do
  echo "== $t =="
  "$PY" "$t"
  tk_result "$t" $?
done

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  "$PY" "examples/$sample.py"
  tk_result "examples/$sample.py" $?
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All Python v0 tests and samples passed."
fi
exit "$rc"
