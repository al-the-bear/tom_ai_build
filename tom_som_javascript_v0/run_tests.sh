#!/usr/bin/env bash
# Runs everything hand-authored in this generated tree:
#   - the behavioural test        (tests/som_v0_generated_test.js)
#   - the metadata agreement test (tests/som_v0_meta_test.js)
#   - the three samples           (examples/a_typed_access.js, b_, c_)
# against the generic runtime resolved through the relative path recorded in
# package.json (`tomSom.runtimePath`).
#
# Mirrors the C / C++ v0 runners: exit 0 == all green. Run from anywhere; it
# cd's to its own directory so the relative runtime path and the meta-data
# default path used by sample (c) resolve.
set -uo pipefail
cd "$(dirname "$0")"

NODE="${NODE:-node}"

rc=0
for t in tests/*_test.js; do
  echo "== $t =="
  "$NODE" "$t" || rc=1
done

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  "$NODE" "examples/$sample.js" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All JavaScript v0 tests and samples passed."
fi
exit "$rc"
