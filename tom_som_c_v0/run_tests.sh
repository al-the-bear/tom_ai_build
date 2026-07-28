#!/usr/bin/env bash
# Builds and runs everything hand-authored in this generated tree:
#   - the behavioural test      (tests/generated_test.c)
#   - the metadata agreement test (tests/meta_agreement_test.c)
#   - the three samples          (examples/a_typed_access.c, b_, c_)
# all linked against the generated typed facade (build/libtom_som_c_v0.a) and
# the generic runtime (../tom_som_c_runtime/build/libtom_som_c_runtime.a).
#
# Mirrors the runtime's `run_tests.sh`: exit 0 == all green. Run from anywhere;
# it cd's to its own directory so the relative RUNTIME_DIR and the meta-data
# default path used by sample (c) resolve. Every test runs even when an earlier
# one fails, so one invocation reports the full picture rather than only the
# first breakage.
set -uo pipefail
cd "$(dirname "$0")"

RUNTIME_DIR="${RUNTIME_DIR:-../tom_som_c_runtime}"
CC="${CC:-cc}"
CFLAGS="${CFLAGS:--std=c11 -Wall -Wextra -O2}"

# 1) Build the generic runtime static library and this typed facade library.
make --no-print-directory -C "$RUNTIME_DIR" || exit 1
make --no-print-directory RUNTIME_DIR="$RUNTIME_DIR" || exit 1

rc=0

LIB="build/libtom_som_c_v0.a"
RUNTIME_LIB="$RUNTIME_DIR/build/libtom_som_c_runtime.a"
INCLUDES="-Iinclude -I$RUNTIME_DIR/include"

# 2) Compile + run the behavioural test (typed facade <-> generic parity).
echo "== behavioural test =="
# shellcheck disable=SC2086
"$CC" $CFLAGS $INCLUDES tests/generated_test.c "$LIB" "$RUNTIME_LIB" \
  -o build/generated_test && ./build/generated_test || rc=1

# 3) Compile + run the metadata agreement test (SOM §8): the generated static
#    trees / dot-notation / ID-tree surfaces agree with the bridge-built trees.
echo "== metadata agreement test =="
# shellcheck disable=SC2086
"$CC" $CFLAGS $INCLUDES tests/meta_agreement_test.c "$LIB" "$RUNTIME_LIB" \
  -o build/meta_agreement_test && ./build/meta_agreement_test || rc=1

# 4) Compile + run the three samples.
for sample in a_typed_access b_generic_document c_reflection_metadata; do
  echo "== sample: $sample =="
  # shellcheck disable=SC2086
  "$CC" $CFLAGS $INCLUDES "examples/$sample.c" "$LIB" "$RUNTIME_LIB" \
    -o "build/$sample" && "./build/$sample" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All C v0 tests and samples passed."
fi
exit "$rc"
