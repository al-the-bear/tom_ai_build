#!/usr/bin/env bash
# Runs everything hand-authored in this package: `go test ./...` over the whole
# module, which covers the shared-corpus conformance suite and every unit test
# under tests/. `run_conformance.sh` runs only the conformance suite; this is
# the full run.
#
# Standard-library only (no module dependencies). Exit 0 == all green.
set -euo pipefail
cd "$(dirname "$0")"

go build ./...
go vet ./...
go test ./... "$@"
