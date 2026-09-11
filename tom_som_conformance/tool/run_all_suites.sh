#!/usr/bin/env bash
# Cross-language suite driver: runs the `run_tests.sh` of every SOM package —
# the nine generic runtimes and the nine generated v0 facades — so a red suite
# surfaces the same way a golden mismatch does. It also runs the one Flutter
# suite that depends on them, the spec-authoring app's, which nothing else runs.
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
#   * A suite is SKIPped only when its toolchain (or, for the editor, the
#     separate tom_forge checkout) is genuinely absent, and a skip
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
#         instantiation-coverage gate (check_sample_coverage.dart),
#         `corpus_copies` for the copied-fixture drift gate,
#         `sample_decode` for the shared-sample decode gate
#         (tom_som_dart_v0/tool/verify_samples.dart), `sample_validate`
#         for the instance-tier gate over the same samples
#         (tom_som_dart_v0/tool/validate_samples.dart), and `editor` for
#         the spec-authoring app's Flutter suite (tom_forge/tom_specs_editor,
#         preceded by _bin/check_pub_cache.sh). With none given, everything
#         runs — the four gates first, then the eighteen suites, then the
#         editor: twenty-three results.
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

# Flutter is usually an SDK checkout that bundles the `dart` on PATH, and — like
# cargo — it is often wired into the interactive profile only. So when
# `flutter` does not resolve: FLUTTER_ROOT when set, else the SDK the resolved
# `dart` belongs to — `<sdk>/bin/dart` or `<sdk>/bin/cache/dart-sdk/bin/dart`,
# after following a symlink. Without either the editor step skips, reason stated.
if ! command -v flutter > /dev/null 2>&1; then
  flutter_bin=""
  if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
    flutter_bin="$FLUTTER_ROOT/bin"
  elif dart_bin="$(command -v dart 2> /dev/null)"; then
    dart_dir="$(dirname "$(realpath "$dart_bin" 2> /dev/null || echo "$dart_bin")")"
    for candidate in "$dart_dir" "$dart_dir/../../.."; do
      if [ -x "$candidate/flutter" ]; then
        flutter_bin="$(cd "$candidate" && pwd)"
        break
      fi
    done
  fi
  if [ -n "$flutter_bin" ]; then
    PATH="$flutter_bin:$PATH"
    export PATH
  fi
fi

CONTAINER="$(cd "$ROOT/../.." && pwd)"   # the workspace root: tom_ai/ai_build/../..
EDITOR_DIR="$CONTAINER/tom_forge/tom_specs_editor"
PUB_CACHE_CHECK="$CONTAINER/_bin/check_pub_cache.sh"

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

# With no names given every step runs; otherwise exactly the named ones.
is_selected() {
  [ ${#SELECTED[@]} -eq 0 ] && return 0
  local s
  for s in "${SELECTED[@]}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

# record_pass NAME [NOTE]
record_pass() {
  RESULTS+=("PASS $1${2:+  ($2)}")
  passed=$((passed + 1))
}

# record_skip NAME REASON — never silent: the reason is on the row.
record_skip() {
  echo "== $1: SKIP ($2) =="
  RESULTS+=("SKIP $1  ($2)")
  skipped=$((skipped + 1))
}

# record_fail NAME LOG [REASON] — prints the log's tail so the cause is visible
# without opening the file.
record_fail() {
  RESULTS+=("FAIL $1  (${3:+$3; }log: $2)")
  failed=$((failed + 1))
  echo "---- $1 failed; last 30 lines of $2 ----"
  tail -30 "$2"
  echo "---- end $1 ----"
}

# run_gate NAME TOOL DIR CMD... — one step: skipped when TOOL is absent, else
# CMD runs in DIR with its output captured to <log-dir>/NAME.log.
run_gate() {
  local name="$1" tool="$2" dir="$3"
  shift 3
  is_selected "$name" || return 0
  echo "== $name =="
  if ! command -v "$tool" > /dev/null 2>&1; then
    record_skip "$name" "$tool not on PATH"
    return 0
  fi
  local log="$LOG_DIR/$name.log"
  if (cd "$dir" && "$@") > "$log" 2>&1; then
    record_pass "$name"
  else
    record_fail "$name" "$log"
  fi
}

# The sample instantiation-coverage gate (SOM §19) runs first: it is
# language-agnostic (Dart model meta vs the shared samples), so it runs once
# here rather than nine times inside the suites.
run_gate sample_coverage dart "$CONF" dart "$HERE/check_sample_coverage.dart" "$CONF"

# The corpus-copy gate: `tom_som_dart_runtime` is published, so two of its
# tests carry COPIES of corpus fixtures rather than reading across the workspace
# instead. A copy nothing compares is a copy that drifts, and the comparison
# has to live here — this package is source-only and may read the workspace,
# which is exactly what the copy exists to spare the published one.
run_gate corpus_copies dart "$CONF" dart "$HERE/check_corpus_copies.dart" "$CONF"

# The shared-sample decode gate: every `samples/*.docspecs.yaml` must decode
# through the typed Dart loader (metadata-tree key matching, SOM §12), so a
# sample that only *looks* structurally plausible — enough to fool the lexical
# coverage scan above — fails here with the offending key and path named.
run_gate sample_decode dart "$ROOT/tom_som_dart_v0" dart run tool/verify_samples.dart

# The shared-sample INSTANCE-TIER gate: every sample must also satisfy
# `validateDocument` (SOM §9) — decoding is not validity. A document can decode
# cleanly and still name a route, message key, error code or step that nothing
# declares; `uam_access_hub` carried eleven such findings from a check that had
# existed for weeks, because nothing ran it against that file. Exemptions are
# written in the tool itself (`coverageOnly`), never implied here.
run_gate sample_validate dart "$ROOT/tom_som_dart_v0" dart run tool/validate_samples.dart

for entry in "${SUITES[@]}"; do
  name="${entry%%:*}"
  tool="${entry##*:}"
  is_selected "$name" || continue

  script="$ROOT/tom_som_$name/run_tests.sh"
  if [ ! -x "$script" ]; then
    # A missing runner is a defect in this repo, not an environment gap.
    echo "== $name: FAIL (no executable run_tests.sh) =="
    RESULTS+=("FAIL $name  (missing $script)")
    failed=$((failed + 1))
    continue
  fi
  if ! command -v "$tool" > /dev/null 2>&1; then
    record_skip "$name" "$tool not on PATH"
    continue
  fi

  log="$LOG_DIR/$name.log"
  echo "== $name =="
  if "$script" > "$log" 2>&1; then
    record_pass "$name"
  else
    record_fail "$name" "$log"
  fi
done

# The spec-authoring app's Flutter suite. It is not a SOM package, and it rides
# here anyway: the editor is a Flutter app outside the release scope, so no
# Dart-only driver and no release step can run it, and this is the driver that
# is run after every model change — which is exactly when the editor breaks.
# Its suite once read as broken for two days with nothing noticing.
#
# The pub-cache check runs first, in the same step, because that breakage was
# pub-cache damage presenting as undefined classes in the editor's
# dependencies. When the cache is damaged the row says so, so the report names
# the cache as the suspect before anyone edits code.
#
# The editor lives in the separate tom_forge checkout; without it the step is
# skipped with that reason, like an absent toolchain.
run_editor() {
  is_selected editor || return 0
  echo "== editor =="
  if [ ! -f "$EDITOR_DIR/pubspec.yaml" ]; then
    record_skip editor "no tom_forge/tom_specs_editor checkout"
    return 0
  fi
  if ! command -v flutter > /dev/null 2>&1; then
    record_skip editor "flutter not on PATH"
    return 0
  fi

  local cache_note="" cache_log="$LOG_DIR/editor_pub_cache.log"
  if [ -x "$PUB_CACHE_CHECK" ]; then
    "$PUB_CACHE_CHECK" --quiet > "$cache_log" 2>&1
    [ $? -eq 1 ] && cache_note="pub cache DAMAGED, see $cache_log"
  fi

  local log="$LOG_DIR/editor.log"
  if (cd "$EDITOR_DIR" && flutter test) > "$log" 2>&1; then
    record_pass editor "$cache_note"
    return 0
  fi
  if [ -n "$cache_note" ]; then
    echo "---- pub cache findings ($cache_log) ----"
    cat "$cache_log"
    cache_note="$cache_note; repair the cache before reading this as a code defect"
  fi
  record_fail editor "$log" "$cache_note"
}
run_editor

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
