#!/usr/bin/env bash
# Runs everything hand-authored in this package: `cargo test` over the crate,
# which covers the shared-corpus conformance suite and every integration test
# under tests/.
#
# Exit 0 == all green.
set -euo pipefail
cd "$(dirname "$0")"

cargo test --quiet "$@"
