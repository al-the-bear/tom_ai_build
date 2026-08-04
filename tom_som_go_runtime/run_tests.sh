#!/usr/bin/env bash
# Runs everything hand-authored in this package: `go test ./...` over the whole
# module, which covers the shared-corpus conformance suite and every unit test
# under tests/. `run_conformance.sh` runs only the conformance suite; this is
# the full run.
#
# Standard-library only (no module dependencies). Exit 0 == all green.
#
# `-count=1` disables Go's test cache. This suite's inputs are the shared
# corpus files, which live OUTSIDE this module
# (`../tom_som_conformance/corpus`), and Go does not invalidate a cached result
# when they change — so a corpus case this runtime did not satisfy was reported
# as `ok (cached)`. A gate that can pass without running is worse than no gate,
# because the harness then claims a parity it never checked (csrf3).
set -euo pipefail
cd "$(dirname "$0")"

go build ./...
go vet ./...
go test ./... -count=1 "$@"
