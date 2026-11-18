#!/usr/bin/env bash
# The memory check of a C or C++ port of a TomSpecs sample: the port's
# `tool/validate.sh` runs this from the port folder. It proves two things the
# output comparison cannot:
#
#   1. MEMORY ERRORS — the port is built with AddressSanitizer and
#      UndefinedBehaviorSanitizer (`make asan` → build/sample_asan) and must run
#      without a report and print the same text as the plain build.
#   2. LEAKS — the plain build (build/sample) must free everything it
#      allocates: macOS `leaks --atExit`, else valgrind
#      (`--leak-check=full --errors-for-leak-kinds=definite,indirect`), else
#      LeakSanitizer through the ASan build (`ASAN_OPTIONS=detect_leaks=1`,
#      Linux). Apple clang's ASan has no leak detection, hence `leaks` there.
#
# Semantics, the same as tool/run_all_samples.sh: a missing tool SKIPs with the
# reason stated and never passes silently; --strict makes a skip a failure.
#
# Usage (from a port folder):  ../../tool/native_memcheck.sh [--strict]
set -uo pipefail

STRICT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

skip() {
  echo "  SKIP     $1"
  [ "$STRICT" -eq 1 ] && { echo "--strict: a skip is a failure."; exit 1; }
  exit 0
}
fail() { echo "  FAIL     $1"; exit 1; }

command -v make > /dev/null 2>&1 || skip "make not on PATH"

# The logs stay in the port's build/ (gitignored), beside the binaries.
log="build/memcheck"
rm -rf "$log" && mkdir -p "$log"

make -s -j4 all > "$log/build.txt" 2>&1 || { tail -n 15 "$log/build.txt"; fail "the plain build failed"; }
if ! make -s -j4 asan > "$log/asan_build.txt" 2>&1; then
  if grep -qi "sanitize" "$log/asan_build.txt"; then
    skip "the compiler does not support -fsanitize=address,undefined"
  fi
  tail -n 15 "$log/asan_build.txt"; fail "the sanitizer build failed"
fi

./build/sample > "$log/plain.txt" 2>&1 || fail "build/sample exited non-zero"
# halt_on_error so UBSan's reports fail the run as ASan's do.
if ! UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1 ASAN_OPTIONS=detect_leaks=0 \
     ./build/sample_asan > "$log/asan.txt" 2>&1; then
  tail -n 25 "$log/asan.txt" | sed 's/^/           /'
  fail "the AddressSanitizer / UBSan build reported an error"
fi
cmp -s "$log/plain.txt" "$log/asan.txt" || fail "the sanitizer build printed different output"
echo "  PASS     AddressSanitizer + UBSan: no memory error, same output"

if [ "$(uname -s)" = "Darwin" ] && command -v leaks > /dev/null 2>&1; then
  if ! leaks --atExit -- ./build/sample > "$log/leaks.txt" 2>&1; then
    grep -E "leaks? for|^Leak:" "$log/leaks.txt" | head -n 10 | sed 's/^/           /'
    fail "leaks --atExit found leaked memory"
  fi
  echo "  PASS     leaks --atExit: $(grep -oE '[0-9]+ leaks? for [0-9]+ total leaked bytes' "$log/leaks.txt")"
elif command -v valgrind > /dev/null 2>&1; then
  if ! valgrind -q --leak-check=full --errors-for-leak-kinds=definite,indirect \
       --error-exitcode=1 ./build/sample > "$log/valgrind.txt" 2>&1; then
    tail -n 25 "$log/valgrind.txt" | sed 's/^/           /'
    fail "valgrind found leaked memory or an error"
  fi
  echo "  PASS     valgrind --leak-check=full: no leak"
elif [ "$(uname -s)" = "Linux" ]; then
  if ! ASAN_OPTIONS=detect_leaks=1 ./build/sample_asan > "$log/lsan.txt" 2>&1; then
    tail -n 25 "$log/lsan.txt" | sed 's/^/           /'
    fail "LeakSanitizer found leaked memory"
  fi
  echo "  PASS     LeakSanitizer: no leak"
else
  skip "no leak checker (leaks, valgrind or LeakSanitizer) on this host"
fi
