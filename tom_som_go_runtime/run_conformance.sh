#!/usr/bin/env bash
# Build + run the Go generic-runtime conformance suite against the shared
# language-agnostic corpus. Standard-library only (no module dependencies):
# `go test` compiles the runtime + the tests/ package and runs the conformance
# suite, which prints "OK: N checks passed" and exits 0 on success.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

go build ./...
go vet ./...
go test ./tests/ -run Conformance -v "$@"
