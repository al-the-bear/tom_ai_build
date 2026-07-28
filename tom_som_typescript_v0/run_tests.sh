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

NODE="${NODE:-node}"

if [ ! -d node_modules ]; then
  npm install || exit 1
fi
npm run --silent build || exit 1

rc=0
for t in dist/tests/*.js; do
  echo "== $t =="
  "$NODE" "$t" || rc=1
done

for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  "$NODE" "dist/examples/$sample.js" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All TypeScript v0 tests and samples passed."
fi
exit "$rc"
