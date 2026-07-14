#!/usr/bin/env bash
# Builds and runs everything hand-authored in this generated tree:
#   - the behavioural test        (tests/generated_test.cpp)
#   - the metadata agreement test (tests/meta_agreement_test.cpp)
#   - the three samples           (examples/a_typed_access.cpp, b_, c_)
# all linked against the generated typed facade (build/libtom_som_cpp_v0.a) and
# the generic runtime (../tom_som_cpp_runtime/build/libtom_som_cpp_runtime.a).
#
# Mirrors the runtime's `run_conformance.sh`: exit 0 == all green. Run from
# anywhere; it cd's to its own directory so the relative RUNTIME_DIR and the
# meta-data default path used by sample (c) resolve.
set -euo pipefail
cd "$(dirname "$0")"

RUNTIME_DIR="${RUNTIME_DIR:-../tom_som_cpp_runtime}"
CXX="${CXX:-g++}"
CXXFLAGS="${CXXFLAGS:--std=c++17 -Wall -Wextra -O2}"

# 1) Build the generic runtime static library and this typed facade library.
make --no-print-directory -C "$RUNTIME_DIR"
make --no-print-directory RUNTIME_DIR="$RUNTIME_DIR"

LIB="build/libtom_som_cpp_v0.a"
RUNTIME_LIB="$RUNTIME_DIR/build/libtom_som_cpp_runtime.a"
INCLUDES="-Iinclude -I$RUNTIME_DIR/include"

# 2) Compile + run the behavioural test (typed facade <-> generic parity).
echo "== behavioural test =="
# shellcheck disable=SC2086
"$CXX" $CXXFLAGS $INCLUDES tests/generated_test.cpp "$LIB" "$RUNTIME_LIB" \
  -o build/generated_test
./build/generated_test

# 3) Compile + run the metadata agreement test (DR33 §4): the generated static
#    trees / dot-notation / ID-tree surfaces agree with the bridge-built trees.
echo "== metadata agreement test =="
# shellcheck disable=SC2086
"$CXX" $CXXFLAGS $INCLUDES tests/meta_agreement_test.cpp "$LIB" "$RUNTIME_LIB" \
  -o build/meta_agreement_test
./build/meta_agreement_test

# 4) Compile + run the three samples.
for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  # shellcheck disable=SC2086
  "$CXX" $CXXFLAGS $INCLUDES "examples/$sample.cpp" "$LIB" "$RUNTIME_LIB" \
    -o "build/$sample"
  "./build/$sample"
  echo
done

echo "All C++ v0 tests and samples passed."
