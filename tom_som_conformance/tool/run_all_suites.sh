#!/usr/bin/env bash
# Cross-language suite driver: runs the `run_tests.sh` of every SOM package —
# the nine generic runtimes and the nine generated v0 facades — so a red suite
# surfaces the same way a golden mismatch does.
#
# Each package owns what "all its tests" means; this script only decides *that*
# they run and reports the outcome. Adding a test file to a package therefore
# needs no edit here.
#
# Semantics, deliberately unlike `regenerate_golden.sh`:
#
#   * It does NOT abort on the first failure. Every suite runs, so one
#     invocation reports the full picture instead of hiding the suites behind
#     the first breakage.
#   * A suite is SKIPped only when its toolchain is genuinely absent, and a skip
#     is never silent: the summary line can never read "all suites passed" when
#     anything was skipped. Pass `--strict` to make a skip a failure — the right
#     setting for CI, where a missing toolchain is itself the defect.
#   * Exit status: 0 only when every suite ran and passed (and, under --strict,
#     nothing was skipped).
#
# Output of each suite goes to `<log-dir>/<suite>.log` (default: a temp dir under
# the workspace's ztmp/). On failure the tail of that log is printed inline so
# the reason is visible without opening the file.
#
# Usage:  ./tool/run_all_suites.sh [--strict] [--log-dir DIR] [suite ...]
#         suite names are package names without the `tom_som_` prefix,
#         e.g. `go_v0 rust_runtime`, plus `sample_coverage` for the SOM §19
#         instantiation-coverage gate (check_sample_coverage.dart) and
#         `sample_decode` for the shared-sample decode gate
#         (tom_som_dart_v0/tool/verify_samples.dart). With none given, all
#         eighteen suites run and the two sample gates run first.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"   # tom_som_conformance/tool
CONF="$(dirname "$HERE")"                # tom_som_conformance
ROOT="$(dirname "$CONF")"                 # ai_build (holds every project)

STRICT=0
LOG_DIR=""
SELECTED=()
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) SELECTED+=("$1"); shift ;;
  esac
done

# rustup installs cargo into ~/.cargo/bin and wires it up in the *interactive*
# shell profile, so a non-interactive run sees no cargo and would skip the two
# Rust suites on a host that can perfectly well run them. A skip that only
# reflects a PATH quirk is nearly as bad as no gate at all, so look there.
if ! command -v cargo > /dev/null 2>&1 && [ -x "$HOME/.cargo/bin/cargo" ]; then
  PATH="$HOME/.cargo/bin:$PATH"
  export PATH
fi

if [ -z "$LOG_DIR" ]; then
  # Never /tmp — the workspace keeps scratch under ztmp/ at its root.
  ztmp="$ROOT/../../ztmp"
  [ -d "$ztmp" ] || ztmp="$ROOT"
  LOG_DIR="$(cd "$ztmp" && pwd)/som_suites_$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$LOG_DIR"

# The eighteen suites, each `<name>:<tool the suite needs on PATH>`. The tool is
# what a skip is decided on — never the presence of the script, which is
# committed and so always there.
SUITES=(
  "dart_runtime:dart"
  "dart_v0:dart"
  "python_runtime:python3"
  "python_v0:python3"
  "javascript_runtime:node"
  "javascript_v0:node"
  "typescript_runtime:npm"
  "typescript_v0:npm"
  "java_runtime:javac"
  "java_v0:javac"
  "go_runtime:go"
  "go_v0:go"
  "rust_runtime:cargo"
  "rust_v0:cargo"
  "c_runtime:cc"
  "c_v0:cc"
  "cpp_runtime:g++"
  "cpp_v0:g++"
)

passed=0
failed=0
skipped=0
declare -a RESULTS=()

# The sample instantiation-coverage gate (SOM §19) runs first: it is
# language-agnostic (Dart model meta vs the shared samples), so it runs once
# here rather than nine times inside the suites. Same skip semantics as a
# suite: absent toolchain skips with the reason stated, never a false pass.
run_coverage=1
if [ ${#SELECTED[@]} -gt 0 ]; then
  run_coverage=0
  for s in "${SELECTED[@]}"; do [ "$s" = "sample_coverage" ] && run_coverage=1; done
fi
if [ "$run_coverage" -eq 1 ]; then
  echo "== sample_coverage =="
  if ! command -v dart > /dev/null 2>&1; then
    echo "== sample_coverage: SKIP (dart not on PATH) =="
    RESULTS+=("SKIP sample_coverage  (dart not on PATH)")
    skipped=$((skipped + 1))
  else
    log="$LOG_DIR/sample_coverage.log"
    if dart "$HERE/check_sample_coverage.dart" "$CONF" > "$log" 2>&1; then
      RESULTS+=("PASS sample_coverage")
      passed=$((passed + 1))
    else
      RESULTS+=("FAIL sample_coverage  (log: $log)")
      failed=$((failed + 1))
      echo "---- sample_coverage failed; last 30 lines of $log ----"
      tail -30 "$log"
      echo "---- end sample_coverage ----"
    fi
  fi
fi

# The shared-sample decode gate: every `samples/*.docspecs.yaml` must decode
# through the typed Dart loader (metadata-tree key matching, SOM §12), so a
# sample that only *looks* structurally plausible — enough to fool the lexical
# coverage scan above — fails here with the offending key and path named.
run_decode=1
if [ ${#SELECTED[@]} -gt 0 ]; then
  run_decode=0
  for s in "${SELECTED[@]}"; do [ "$s" = "sample_decode" ] && run_decode=1; done
fi
if [ "$run_decode" -eq 1 ]; then
  echo "== sample_decode =="
  if ! command -v dart > /dev/null 2>&1; then
    echo "== sample_decode: SKIP (dart not on PATH) =="
    RESULTS+=("SKIP sample_decode  (dart not on PATH)")
    skipped=$((skipped + 1))
  else
    log="$LOG_DIR/sample_decode.log"
    if (cd "$ROOT/tom_som_dart_v0" && dart run tool/verify_samples.dart) > "$log" 2>&1; then
      RESULTS+=("PASS sample_decode")
      passed=$((passed + 1))
    else
      RESULTS+=("FAIL sample_decode  (log: $log)")
      failed=$((failed + 1))
      echo "---- sample_decode failed; last 30 lines of $log ----"
      tail -30 "$log"
      echo "---- end sample_decode ----"
    fi
  fi
fi

for entry in "${SUITES[@]}"; do
  name="${entry%%:*}"
  tool="${entry##*:}"

  if [ ${#SELECTED[@]} -gt 0 ]; then
    wanted=0
    for s in "${SELECTED[@]}"; do [ "$s" = "$name" ] && wanted=1; done
    [ "$wanted" -eq 1 ] || continue
  fi

  script="$ROOT/tom_som_$name/run_tests.sh"
  if [ ! -x "$script" ]; then
    # A missing runner is a defect in this repo, not an environment gap.
    echo "== $name: FAIL (no executable run_tests.sh) =="
    RESULTS+=("FAIL $name  (missing $script)")
    failed=$((failed + 1))
    continue
  fi

  if ! command -v "$tool" > /dev/null 2>&1; then
    echo "== $name: SKIP ($tool not on PATH) =="
    RESULTS+=("SKIP $name  ($tool not on PATH)")
    skipped=$((skipped + 1))
    continue
  fi

  log="$LOG_DIR/$name.log"
  echo "== $name =="
  if "$script" > "$log" 2>&1; then
    RESULTS+=("PASS $name")
    passed=$((passed + 1))
  else
    RESULTS+=("FAIL $name  (log: $log)")
    failed=$((failed + 1))
    echo "---- $name failed; last 30 lines of $log ----"
    tail -30 "$log"
    echo "---- end $name ----"
  fi
done

echo
echo "== suite summary =="
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "  logs: $LOG_DIR"
echo

if [ "$failed" -gt 0 ]; then
  echo "FAILED: $passed passed, $failed failed, $skipped skipped."
  exit 1
fi
if [ "$skipped" -gt 0 ]; then
  if [ "$STRICT" -eq 1 ]; then
    echo "FAILED (--strict): $passed passed, 0 failed, $skipped skipped."
    exit 1
  fi
  # Never "all suites passed" while a suite went unrun.
  echo "INCOMPLETE: $passed passed, 0 failed, $skipped skipped."
  exit 0
fi
echo "All $passed suites passed."
