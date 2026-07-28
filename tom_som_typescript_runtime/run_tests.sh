#!/usr/bin/env bash
# Runs everything hand-authored in this package: `tsc` compiles src/ + tests/ to
# dist/, then every compiled test is run with plain `node`. Each test file ends
# in `process.exit(main())` (or exits 1 itself on failure), so the run is the
# whole contract: exit 0 == green.
#
# `tests/conformance_runner.ts` is both a module and a `require.main` script, so
# it is included in the loop rather than run separately.
#
# Project-local toolchain only: `npm install` brings the pinned `tsc`
# (typescript@6.0.3) + `@types/node`. Exit 0 == all green. Every test runs even
# when an earlier one fails, so one invocation reports the full picture.
set -uo pipefail
cd "$(dirname "$0")"

NODE="${NODE:-node}"

if [ ! -d node_modules ]; then
  npm install || exit 1
fi
./node_modules/.bin/tsc || exit 1

rc=0
for t in dist/tests/*.js; do
  echo "== $t =="
  "$NODE" "$t" || rc=1
done

if [ "$rc" -eq 0 ]; then
  echo "All TypeScript runtime tests passed."
fi
exit "$rc"
