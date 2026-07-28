#!/usr/bin/env bash
# Runs everything hand-authored in this package: the shared-corpus conformance
# runner plus every standalone unit test under tests/. Zero external tooling
# beyond `python3` and the package's own PyYAML dependency.
#
# Every test file is a dependency-free script ending in
# `raise SystemExit(main())`, so a plain `python3 tests/<file>.py` is the whole
# contract: exit 0 == green. PYTHONPATH points at this project root so the
# `tom_som_runtime` package under test resolves without an install.
#
# Exit 0 == all green. Every test runs even when an earlier one fails, so one
# invocation reports the full picture rather than only the first breakage.
set -uo pipefail
cd "$(dirname "$0")"

export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"
PY="${PYTHON:-python3}"

rc=0
for t in tests/*.py; do
  echo "== $t =="
  "$PY" "$t" || rc=1
done

if [ "$rc" -eq 0 ]; then
  echo "All Python runtime tests passed."
fi
exit "$rc"
