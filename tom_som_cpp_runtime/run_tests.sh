#!/usr/bin/env bash
# Runs everything hand-authored in this package:
#   - `make test`     — the conformance harness against the shared corpus
#   - `make unittest` — every standalone unit test under tests/ (no corpus)
# `run_conformance.sh` runs only the first of those; this is the full run.
#
# Exit 0 == all green. Both halves run even when the first fails, so one
# invocation reports the full picture rather than only the first breakage.
set -uo pipefail
cd "$(dirname "$0")"

CORPUS="${1:-../tom_som_conformance/corpus}"

rc=0
echo "== conformance harness =="
make --no-print-directory test CORPUS="$CORPUS" || rc=1

echo "== unit tests =="
make --no-print-directory unittest || rc=1

if [ "$rc" -eq 0 ]; then
  echo "All C++ runtime tests passed."
fi
exit "$rc"
