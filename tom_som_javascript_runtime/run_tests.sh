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

# testkit (`testkit :baseline` / `:test`) sets TESTKIT_REPORT: every test below
# then adds one result line to that file (tom_test_kit's line protocol, one
# JSON object per line). tk_result also folds the test's exit code into rc.
tk_result() { # <test name> <exit code>
  if [ -n "${TESTKIT_REPORT:-}" ]; then
    local result=ok
    [ "$2" -eq 0 ] || result=fail
    printf '{"test":"%s","result":"%s"}\n' "$1" "$result" >>"$TESTKIT_REPORT"
  fi
  [ "$2" -eq 0 ] || rc=1
}

NODE="${NODE:-node}"

rc=0
for t in tests/*.test.js; do
  echo "== node --test $t =="
  "$NODE" --test "$t"
  tk_result "$t" $?
done

for t in tests/*_test.js; do
  echo "== $t =="
  "$NODE" "$t"
  tk_result "$t" $?
done

if [ "$rc" -eq 0 ]; then
  echo "All JavaScript runtime tests passed."
fi
exit "$rc"
