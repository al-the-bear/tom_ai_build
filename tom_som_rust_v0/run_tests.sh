#!/usr/bin/env bash
# Runs everything hand-authored in this generated tree:
#   - `cargo test` — the behavioural test (tests/som_v0_generated_test.rs) and
#     the metadata agreement test (tests/som_v0_meta_test.rs)
#   - the three samples (examples/a_typed_access.rs, b_, c_)
# The `golden_log` example is driven by regenerate_golden.sh, not by the test
# run.
#
# Mirrors the C / C++ v0 runners: exit 0 == all green. Run from anywhere; it
# cd's to its own directory so the meta-data default path used by sample (c)
# resolves.
set -uo pipefail
cd "$(dirname "$0")"

rc=0
echo "== cargo test =="
cargo test --quiet || rc=1

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  cargo run --quiet --example "$sample" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All Rust v0 tests and samples passed."
fi
exit "$rc"
