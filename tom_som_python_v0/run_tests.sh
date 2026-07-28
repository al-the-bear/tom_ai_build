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

RUNTIME_DIR="${RUNTIME_DIR:-../tom_som_python_runtime}"
export PYTHONPATH="$PWD:$RUNTIME_DIR${PYTHONPATH:+:$PYTHONPATH}"
PY="${PYTHON:-python3}"

rc=0
for t in tests/*.py; do
  echo "== $t =="
  "$PY" "$t" || rc=1
done

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  "$PY" "examples/$sample.py" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All Python v0 tests and samples passed."
fi
exit "$rc"
