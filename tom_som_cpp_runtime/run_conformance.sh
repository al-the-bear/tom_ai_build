#!/usr/bin/env bash
# Builds and runs the C++ runtime conformance harness against the shared corpus.
# Mirrors the C port's runner: exit 0 == all green.
set -euo pipefail
cd "$(dirname "$0")"
CORPUS="${1:-../tom_som_conformance/corpus}"
make --no-print-directory test CORPUS="$CORPUS"
