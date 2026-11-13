#!/usr/bin/env bash
# Runs everything hand-authored in this generated tree:
#   - the behavioural test        (tests/som_v0_generated_test.ts)
#   - the metadata agreement test (tests/som_v0_meta_test.ts)
#   - the three samples           (examples/a_typed_access.ts, b_, c_)
# `npm run build` compiles the facade, the tests, the samples and the golden
# tool to dist/; its `prebuild` hook builds the runtime first so the facade's
# bare `tom_som_typescript_runtime` import resolves.
#
# Mirrors the C / C++ v0 runners: exit 0 == all green. Run from anywhere; it
# cd's to its own directory so the meta-data default path used by sample (c)
# resolves.
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

if [ ! -d node_modules ]; then
  npm install || exit 1
fi
# Compiled tests of deleted sources would otherwise linger in dist/ (it is
# gitignored) and keep running: the loop below runs whatever is there.
rm -rf dist/tests
npm run --silent build || exit 1

rc=0
for t in dist/tests/*.js; do
  echo "== $t =="
  "$NODE" "$t"
  tk_result "tests/$(basename "$t" .js).ts" $?
done

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  "$NODE" "dist/examples/$sample.js"
  tk_result "examples/$sample.ts" $?
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All TypeScript v0 tests and samples passed."
fi
exit "$rc"
