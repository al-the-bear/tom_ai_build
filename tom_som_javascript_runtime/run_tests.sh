#!/usr/bin/env bash
# Runs everything hand-authored in this package. The tests come in two shapes,
# so the script has two halves:
#   - `tests/*.test.js`  — node:test suites (including the conformance wrapper),
#                          run together under the built-in `node --test` runner
#   - `tests/*_test.js`  — dependency-free scripts ending in
#                          `process.exit(main())`, run one by one
# `tests/conformance_runner.js` is a module the wrapper imports, not a test, so
# it is not run twice.
#
# Zero external dependencies: Node built-ins only. Exit 0 == all green. Every
# test runs even when an earlier one fails, so one invocation reports the full
# picture rather than only the first breakage.
set -uo pipefail
cd "$(dirname "$0")"

NODE="${NODE:-node}"

rc=0
echo "== node --test tests/*.test.js =="
"$NODE" --test tests/*.test.js || rc=1

for t in tests/*_test.js; do
  echo "== $t =="
  "$NODE" "$t" || rc=1
done

if [ "$rc" -eq 0 ]; then
  echo "All JavaScript runtime tests passed."
fi
exit "$rc"
