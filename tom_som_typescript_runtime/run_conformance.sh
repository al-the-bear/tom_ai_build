#!/usr/bin/env bash
# Build + run the TypeScript generic-runtime conformance suite against the shared
# language-agnostic corpus. Project-local toolchain only: `npm install` brings the
# pinned `tsc` (typescript@6.0.3) + `@types/node`, `tsc` compiles src+tests to
# dist/, then a plain `node` run of the compiled conformance_runner.js main()
# exits 0 on success.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

if [ ! -d node_modules ]; then
  npm install
fi

./node_modules/.bin/tsc
node "$here/dist/tests/conformance_runner.js" "$@"
