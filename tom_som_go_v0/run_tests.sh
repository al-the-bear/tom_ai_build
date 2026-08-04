#!/usr/bin/env bash
# Runs everything hand-authored in this generated tree:
#   - `go test ./...` — the behavioural test (som_v0_generated_test.go) and the
#     metadata agreement test (som_v0_meta_test.go)
#   - the three samples (examples/a_typed_access, b_generic_document,
#     c_reflection_metadata), each its own main package
#
# Mirrors the C / C++ v0 runners: exit 0 == all green. Run from anywhere; it
# cd's to its own directory so the meta-data default path used by sample (c)
# resolves.
#
# `-count=1` disables Go's test cache for the same reason as the runtime's
# runner: these tests read shared assets from outside the module, which Go does
# not treat as cache inputs, so a stale `ok (cached)` can hide a real failure.
set -uo pipefail
cd "$(dirname "$0")"

rc=0
go build ./... || rc=1
go vet ./... || rc=1

echo "== go test ./... =="
go test ./... -count=1 || rc=1

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  go run "./examples/$sample" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All Go v0 tests and samples passed."
fi
exit "$rc"
