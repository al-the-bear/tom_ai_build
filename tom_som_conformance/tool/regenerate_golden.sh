#!/usr/bin/env bash
# Cross-language golden-log driver (roadmap item 7b).
#
# Builds and runs every `tom_som_<lang>_v0` golden generator, each of which
# writes a canonical reading of the shared sample to
# `tom_som_conformance/golden/<lang>.log`, then runs `compare_golden.dart` to
# assert all nine logs are byte-identical. Exit 0 == all nine languages yield
# exactly the same reading of the same specification.
#
# Each generator is run from its own project directory because they address the
# sample and their output via the relative path `../tom_som_conformance/...`.
#
# Usage:  ./tool/regenerate_golden.sh
# Requires the nine toolchains on PATH (dart, python3, node, tsc via npm, java +
# javac, go, cargo, cc, g++). Run from anywhere; it cd's to the ai_build root.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"          # tom_som_conformance/tool
CONF="$(dirname "$HERE")"                        # tom_som_conformance
ROOT="$(dirname "$CONF")"                         # ai_build (holds every project)
cd "$ROOT"

# rustup installs cargo into ~/.cargo/bin and wires it up in the *interactive*
# shell profile, so a non-interactive run sees no cargo and dies at `run rust`
# on a host that can perfectly well build it. Same prepend as run_all_suites.sh.
if ! command -v cargo > /dev/null 2>&1 && [ -x "$HOME/.cargo/bin/cargo" ]; then
  PATH="$HOME/.cargo/bin:$PATH"
  export PATH
fi

run() { echo "== golden: $1 =="; }

run dart
( cd tom_som_dart_v0 && dart run tool/golden_log.dart )

run python
( cd tom_som_python_v0 && python3 tool/golden_log.py )

run javascript
( cd tom_som_javascript_v0 && node tool/golden_log.js )

run typescript
# The v0 tsconfig includes tool/; the runtime dist must be built first so the
# facade's bare `tom_som_typescript_runtime` import resolves (CS4-D6).
( cd tom_som_typescript_runtime && npm run --silent build )
( cd tom_som_typescript_v0 && npm run --silent build && node dist/tool/golden_log.js )

run go
( cd tom_som_go_v0 && go run ./tool )

run java
( cd tom_som_java_v0 \
    && javac -d build_tool -sourcepath src:../tom_som_java_runtime/src tool/GoldenLog.java \
    && java -cp build_tool GoldenLog )

run rust
( cd tom_som_rust_v0 && cargo run --quiet --example golden_log )

run c
( cd tom_som_c_v0 \
    && make --no-print-directory -C ../tom_som_c_runtime \
    && make --no-print-directory RUNTIME_DIR=../tom_som_c_runtime \
    && cc -std=c11 -Wall -Wextra -O2 -Iinclude -I../tom_som_c_runtime/include \
         tool/golden_log.c build/libtom_som_c_v0.a \
         ../tom_som_c_runtime/build/libtom_som_c_runtime.a -o build/golden_log \
    && ./build/golden_log )

run cpp
( cd tom_som_cpp_v0 \
    && make --no-print-directory -C ../tom_som_cpp_runtime \
    && make --no-print-directory RUNTIME_DIR=../tom_som_cpp_runtime \
    && g++ -std=c++17 -Wall -Wextra -O2 -Iinclude -I../tom_som_cpp_runtime/include \
         tool/golden_log.cpp build/libtom_som_cpp_v0.a \
         ../tom_som_cpp_runtime/build/libtom_som_cpp_runtime.a -o build/golden_log \
    && ./build/golden_log )

echo
echo "== comparing all nine logs =="
( cd "$CONF" && dart run tool/compare_golden.dart )
