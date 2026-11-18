#!/usr/bin/env bash
# Sample driver: runs every sample project in tom_specs_samples/ and compares
# what it prints against the `expected_output.txt` beside it.
#
# A sample with no expected output is a demo, not a test: nobody would notice it
# breaking, and documentation nobody would notice breaking quietly stops being
# true. This script is what makes the samples a gate.
#
# Semantics, deliberately the same as tom_som_conformance/tool/run_all_suites.sh
# and for the reasons its header gives:
#
#   * It does NOT abort on the first failure. Every sample runs, so one
#     invocation reports the full picture instead of hiding the rest behind the
#     first breakage.
#   * A sample is SKIPped only when its toolchain is genuinely absent, and a
#     skip is never silent: the summary can never read "all samples passed"
#     when anything was skipped. Pass --strict to make a skip a failure, which
#     is the right setting for CI, where a missing toolchain is itself the
#     defect.
#   * Exit status: 0 only when every sample ran and passed (and, under
#     --strict, nothing was skipped).
#   * An EMPTY sample set passes. The folder is scaffolded before the samples
#     land, and a driver that failed on nothing to do would have to be
#     disabled until the first sample arrived — which is when a gate is most
#     easily forgotten.
#
# Each sample's output goes to <log-dir>/<sample>.log (default: a temp dir under
# the workspace ztmp/). On failure the diff against the expected output is
# printed inline, so the reason is visible without opening the file.
#
# A sample's ports to other languages sit beside it, one folder per language
# (`<sample>/python/`, … — the samples README, § Per language), and run as
# samples of their own, named `<sample>/<language>`. A port compares against
# its own `expected_output.txt` when it has one (its output differs from the
# Dart sample's, and its README says why), else against the Dart sample's.
#
# Usage:  ./tool/run_all_samples.sh [--strict] [--log-dir DIR] [sample ...]
#         sample names are directory names, e.g. `author_solution_blueprint`,
#         or `author_solution_blueprint/python` for one port.
#         With none given, every sample and every port runs.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"     # tom_specs_samples/tool
SAMPLES="$(dirname "$HERE")"              # tom_specs_samples
ROOT="$(dirname "$SAMPLES")"              # ai_build

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

if [ -z "$LOG_DIR" ]; then
  LOG_DIR="$(cd "$ROOT/../.." && pwd)/ztmp/sample_logs"
fi
mkdir -p "$LOG_DIR"

# A sample is any directory holding a README.md — the convention's minimum.
# Discovered rather than listed, so adding one needs no edit here. Its ports
# are the language folders beside its source that hold a README.md too.
PORT_LANGUAGES=(python javascript typescript go rust java c cpp)
discover() {
  local d lang
  for d in "$SAMPLES"/*/; do
    d="${d%/}"
    [ "$(basename "$d")" = "tool" ] && continue
    [ -f "$d/README.md" ] || continue
    basename "$d"
    for lang in "${PORT_LANGUAGES[@]}"; do
      [ -f "$d/$lang/README.md" ] && echo "$(basename "$d")/$lang"
    done
  done
}

if [ ${#SELECTED[@]} -gt 0 ]; then
  NAMES=("${SELECTED[@]}")
else
  # `read -a` rather than a pipeline so an empty discovery yields an empty
  # array instead of one empty-string element.
  NAMES=()
  while IFS= read -r line; do
    [ -n "$line" ] && NAMES+=("$line")
  done < <(discover)
fi

PASSED=(); FAILED=(); SKIPPED=()

run_one() {
  local name="$1"
  local dir="$SAMPLES/$name"
  local log="$LOG_DIR/${name//\//__}.log"

  if [ ! -d "$dir" ]; then
    echo "  MISSING  $name — no such sample directory"
    FAILED+=("$name")
    return
  fi
  # A port without its own expected output has the Dart sample's.
  local expected="$dir/expected_output.txt"
  if [ ! -f "$expected" ] && [[ "$name" == */* ]]; then
    expected="$(dirname "$dir")/expected_output.txt"
  fi
  if [ ! -f "$expected" ]; then
    echo "  FAIL     $name — no expected_output.txt; a sample without one is a"
    echo "                    demo, not a gate (see the samples README)"
    FAILED+=("$name")
    return
  fi

  # Per-language entry points. Each is tried in turn; the first that matches
  # decides how the sample runs. A sample whose language has no rule here is
  # SKIPped with that stated, never silently passed.
  local cmd=()
  if [ -f "$dir/pubspec.yaml" ]; then
    if ! command -v dart > /dev/null 2>&1; then
      echo "  SKIP     $name — dart not on PATH"
      SKIPPED+=("$name"); return
    fi
    cmd=(dart run)
  elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/main.py" ]; then
    if ! command -v python3 > /dev/null 2>&1; then
      echo "  SKIP     $name — python3 not on PATH"
      SKIPPED+=("$name"); return
    fi
    # The Python runtimes are not published (decided 2026-11-18): a sample
    # runs on the checkout's packages, as its README's source install does.
    # The runtime needs PyYAML; without it the toolchain is incomplete.
    if ! python3 -c 'import yaml' > /dev/null 2>&1; then
      echo "  SKIP     $name — python3 has no PyYAML (pip install PyYAML)"
      SKIPPED+=("$name"); return
    fi
    cmd=(env "PYTHONPATH=$ROOT/tom_som_python_runtime:$ROOT/tom_som_python_v0${PYTHONPATH:+:$PYTHONPATH}"
         python3 main.py)
  elif [ -f "$dir/go.mod" ]; then
    if ! command -v go > /dev/null 2>&1; then
      echo "  SKIP     $name — go not on PATH"
      SKIPPED+=("$name"); return
    fi
    cmd=(go run .)
  elif [ -f "$dir/Cargo.toml" ]; then
    if ! command -v cargo > /dev/null 2>&1; then
      echo "  SKIP     $name — cargo not on PATH"
      SKIPPED+=("$name"); return
    fi
    cmd=(cargo run --quiet)
  elif [ -f "$dir/package.json" ]; then
    if ! command -v node > /dev/null 2>&1; then
      echo "  SKIP     $name — node not on PATH"
      SKIPPED+=("$name"); return
    fi
    if ! command -v npm > /dev/null 2>&1; then
      echo "  SKIP     $name — npm not on PATH"
      SKIPPED+=("$name"); return
    fi
    # A TypeScript sample (a tsconfig.json) runs what `npm run build` compiled.
    if [ -f "$dir/tsconfig.json" ]; then
      cmd=(node dist/index.js)
    else
      cmd=(node index.js)
    fi
  else
    echo "  SKIP     $name — no recognised entry point (pubspec.yaml,"
    echo "                    main.py, go.mod, Cargo.toml or package.json)"
    SKIPPED+=("$name"); return
  fi

  # A Dart sample must resolve its published dependencies first. `pub get` is
  # part of running the sample as a user would, so its failure is the sample's.
  if [ -f "$dir/pubspec.yaml" ]; then
    if ! (cd "$dir" && dart pub get) > "$log" 2>&1; then
      echo "  FAIL     $name — dart pub get failed"
      tail -n 15 "$log" | sed 's/^/             /'
      FAILED+=("$name"); return
    fi
  fi

  # A Node sample installs its dependencies first — the non-Dart runtimes are
  # `file:` dependencies on the checkout, so this links them rather than
  # fetching them (a TypeScript sample also fetches its compiler, a
  # devDependency). Its failure is the sample's, like `dart pub get`'s.
  if [ -f "$dir/package.json" ] && [ ! -f "$dir/pubspec.yaml" ]; then
    if ! (cd "$dir" && npm install --no-audit --no-fund) > "$log" 2>&1; then
      echo "  FAIL     $name — npm install failed"
      tail -n 15 "$log" | sed 's/^/             /'
      FAILED+=("$name"); return
    fi
    # A TypeScript sample builds the two packages it links (their dist/ is not
    # committed) and compiles itself with tsc; a type error fails the sample.
    if [ -f "$dir/tsconfig.json" ]; then
      if ! (cd "$dir" && npm run build) > "$log" 2>&1; then
        echo "  FAIL     $name — npm run build failed"
        tail -n 15 "$log" | sed 's/^/             /'
        FAILED+=("$name"); return
      fi
    fi
  fi

  if ! (cd "$dir" && "${cmd[@]}") > "$log" 2>&1; then
    echo "  FAIL     $name — exited non-zero"
    tail -n 15 "$log" | sed 's/^/             /'
    FAILED+=("$name"); return
  fi

  if diff -q "$expected" "$log" > /dev/null 2>&1; then
    # A sample whose output records something a workspace tool produced needs a
    # second gate: the stdout diff proves the sample still prints its record,
    # not that the record is still true. `tool/validate.sh` is the convention
    # for that — it re-derives the recorded artifact and fails when it is
    # stale. Optional, and its own SKIP/--strict semantics are the same as this
    # script's, so an absent toolchain is reported rather than passed.
    if [ -x "$dir/tool/validate.sh" ]; then
      local vlog="$LOG_DIR/${name//\//__}.validate.log"
      local vargs=()
      [ "$STRICT" -eq 1 ] && vargs+=(--strict)
      if ! (cd "$dir" && ./tool/validate.sh "${vargs[@]+"${vargs[@]}"}") \
          > "$vlog" 2>&1; then
        echo "  FAIL     $name — tool/validate.sh reported a stale record"
        cat "$vlog" | head -n 20 | sed 's/^/             /'
        FAILED+=("$name"); return
      fi
      sed 's/^  /           /' "$vlog"
    fi
    echo "  PASS     $name"
    PASSED+=("$name")
  else
    echo "  FAIL     $name — output differs from expected_output.txt"
    diff -u "$expected" "$log" | head -n 30 \
      | sed 's/^/             /'
    FAILED+=("$name")
  fi
}

echo "Running ${#NAMES[@]} sample(s); logs in $LOG_DIR"
for name in "${NAMES[@]+"${NAMES[@]}"}"; do
  run_one "$name"
done

echo
echo "passed ${#PASSED[@]}  failed ${#FAILED[@]}  skipped ${#SKIPPED[@]}"

if [ ${#FAILED[@]} -gt 0 ]; then
  echo "FAILED: ${FAILED[*]}"
  exit 1
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo "SKIPPED: ${SKIPPED[*]}"
  if [ "$STRICT" -eq 1 ]; then
    echo "--strict: a skip is a failure."
    exit 1
  fi
  echo "Not all samples ran — this is NOT a clean pass."
  exit 0
fi
if [ ${#NAMES[@]} -eq 0 ]; then
  echo "No samples yet — the folder is scaffolded and the driver is ready."
  exit 0
fi
echo "OK — every sample ran and matched its expected output."
