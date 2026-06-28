#!/usr/bin/env bash
# Run the JavaScript generic-runtime conformance suite against the shared
# language-agnostic corpus. Zero external dependencies: a plain `node` run of the
# conformance_runner.js main(), which exits 0 on success.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
node "$here/tests/conformance_runner.js" "$@"
