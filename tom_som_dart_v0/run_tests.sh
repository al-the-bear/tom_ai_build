#!/usr/bin/env bash
# Runs everything hand-authored in this generated tree:
#   - `dart test` over test/ — the behavioural test (generated_v0_test.dart)
#     and the metadata agreement test (generated_meta_test.dart)
#   - the three samples (example/a_typed_access.dart, b_, c_)
# The three `d_`/`e_`/`f_` shared-sample examples are driven by
# tool/build_shared_sample.dart and are not part of the test run.
#
# Mirrors the C / C++ v0 runners: exit 0 == all green. Run from anywhere; it
# cd's to its own directory so the meta-data default path used by sample (c)
# resolves.
set -uo pipefail
cd "$(dirname "$0")"

dart pub get --offline > /dev/null 2>&1 || dart pub get || exit 1

rc=0
echo "== dart test =="
dart test || rc=1

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  dart run "example/$sample.dart" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All Dart v0 tests and samples passed."
fi
exit "$rc"
