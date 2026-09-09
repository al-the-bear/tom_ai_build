#!/usr/bin/env bash
# Runs every published release package's own tests THE WAY A CONSUMER WOULD:
# from the archive on pub.dev, against dependencies resolved from pub.dev, in a
# directory with no workspace siblings.
#
# WHY IT EXISTS. `check_shipped_paths.dart` is a LEXICAL gate — it reads path
# literals — and it reported `tom_som_dart_runtime` clean while two of that
# package's shipped tests could not run from a hosted install at all, because
# they build their paths from `Directory.current` plus components rather than
# from a `../` literal. Worse, the fixtures those tests read were UNTRACKED in
# git, so `dart pub publish` (which ships what git knows about) would have left
# them out of the archive entirely: the shipped test would have failed for a
# consumer while passing in the workspace. No check that reads source can see
# that. Only running the archive can.
#
# WHAT IT DOWNLOADS, and why that rather than a reconstruction. It fetches the
# ACTUAL archive from pub.dev rather than rebuilding one from `git ls-files`
# minus `.pubignore`. A reconstruction re-implements pub's packaging rules and
# would have reproduced the very bug above — the untracked-fixture case is
# invisible unless the thing you run is the thing that shipped.
#
# WHEN IT IS FAITHFUL, which is the whole reason this is a RELEASE STEP and not
# a standing gate. The archive's tests are only meaningful against the archive's
# dependencies. `tom_doc_specs`'s local tree once failed this simulation for a
# combination that does not exist on pub.dev at all — its local code against a
# published `tom_doc_scanner` that predated the fixes it relies on — and a check
# that reports that as a failure teaches a reader to ignore it. So this runs
# AFTER a lockstep publish, when local and published agree by construction, and
# it refuses to start when they do not: `check_release_drift.dart` is the
# precondition, and `--allow-drift` is the deliberate override.
#
# Usage:  ./tool/verify_published_tests.sh [--strict] [--allow-drift]
#                                          [--log-dir DIR] [package ...]
#
#   --strict       a skip is a failure (the right setting for a release gate)
#   --allow-drift  run even when the release-drift gate is red; the verdict is
#                  then not a statement about what is published
#
# Exit 0 only when every package ran and passed (and, under --strict, nothing
# was skipped). Like `run_all_suites.sh` it does NOT abort on the first failure,
# and the summary can never read "all passed" while anything was skipped.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"          # tom_specs_clitool/tool
CLITOOL="$(dirname "$HERE")"                    # tom_specs_clitool
ROOT="$(dirname "$CLITOOL")"                     # ai_build
CONTAINER="$(cd "$ROOT/../.." && pwd)"           # tom_agent_container

STRICT=0
ALLOW_DRIFT=0
LOG_DIR=""
SELECTED=()
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --allow-drift) ALLOW_DRIFT=1; shift ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,47p' "$0"; exit 0 ;;
    *) SELECTED+=("$1"); shift ;;
  esac
done

if [ -z "$LOG_DIR" ]; then
  LOG_DIR="$CONTAINER/ztmp/published_tests_$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$LOG_DIR"

# The Dart members of the release set, read from the committed manifest rather
# than listed here: two lists of the release scope would be one too many.
# `mapfile` is bash 4+; macOS still ships 3.2 as /bin/bash, and a driver that
# silently reads nothing there would report "all passed" over no packages.
PACKAGES=()
while IFS= read -r line; do
  [ -n "$line" ] && PACKAGES+=("$line")
done < <(
  awk '/^release_set:/{f=1;next} /^[a-z0-9_]+:/{f=0} f && /^  [a-z0-9_]+:/{
        gsub(/:/,"",$1); print $1" "$2 }' "$CLITOOL/tool/release_set.yaml"
)

# COUNTED A SECOND WAY, because the first way was wrong. The key regex read
# `[a-z_]+` and so skipped `tom_som_dart_v0` for its digit -- and the run then
# reported "5 passed" over eight of nine members without saying anything was
# missing. A driver whose subject can shrink silently is worse than no driver.
# This counts the block's entries by a rule that shares nothing with the parse
# above, so both would have to be wrong the same way.
expected=$(awk '/^release_set:/{f=1;next} /^[^ #]/{f=0} f && NF && $1 !~ /^#/{n++} END{print n+0}'   "$CLITOOL/tool/release_set.yaml")
if [ "${#PACKAGES[@]}" -ne "$expected" ]; then
  echo "verify_published_tests: parsed ${#PACKAGES[@]} release member(s) but the" >&2
  echo "  manifest's release_set: block has $expected. The parse is dropping one," >&2
  echo "  which would silently shrink what this driver covers." >&2
  exit 1
fi
if [ "${#PACKAGES[@]}" -eq 0 ]; then
  echo "verify_published_tests: no release members parsed from release_set.yaml" >&2
  exit 1
fi

# ── the precondition ────────────────────────────────────────────────────────
if [ "$ALLOW_DRIFT" -eq 0 ]; then
  echo "== precondition: local tree == published tree =="
  if ! ( cd "$CLITOOL" && dart run bin/check_release_drift.dart > "$LOG_DIR/drift.log" 2>&1 ); then
    tail -n 20 "$LOG_DIR/drift.log" | sed 's/^/    /'
    echo
    echo "verify_published_tests: REFUSED — a release member has unpublished changes," >&2
    echo "  so running the published archive would answer a question about a tree that" >&2
    echo "  no longer exists. Publish the set first, or pass --allow-drift." >&2
    exit 1
  fi
  echo "  clean"
fi

RESULTS=()
passed=0; failed=0; skipped=0

want() {
  [ "${#SELECTED[@]}" -eq 0 ] && return 0
  local p
  for p in "${SELECTED[@]}"; do [ "$p" = "$1" ] && return 0; done
  return 1
}

for entry in "${PACKAGES[@]}"; do
  name="${entry%% *}"
  dir="${entry##* }"
  want "$name" || continue

  pubspec="$CONTAINER/$dir/pubspec.yaml"
  version="$(awk '/^version:/{print $2; exit}' "$pubspec" 2>/dev/null)"
  log="$LOG_DIR/$name.log"

  if [ -z "$version" ]; then
    RESULTS+=("SKIP $name — no version in $dir/pubspec.yaml")
    skipped=$((skipped+1)); continue
  fi

  echo "== $name $version =="
  work="$LOG_DIR/work/$name"
  rm -rf "$work"; mkdir -p "$work"

  url="https://pub.dev/api/archives/$name-$version.tar.gz"
  if ! curl -fsSL "$url" -o "$work/pkg.tar.gz" 2> "$log"; then
    RESULTS+=("SKIP $name — $version is not on pub.dev yet (propagation can take minutes)")
    skipped=$((skipped+1)); continue
  fi
  tar -xzf "$work/pkg.tar.gz" -C "$work" >> "$log" 2>&1
  rm -f "$work/pkg.tar.gz"

  # A path override in the archive would defeat the whole point; pub excludes it
  # from published archives, and this is the belt to that braces.
  rm -f "$work/pubspec_overrides.yaml"

  if [ ! -d "$work/test" ]; then
    RESULTS+=("SKIP $name — the published archive carries no test/ directory")
    skipped=$((skipped+1)); continue
  fi

  if ! ( cd "$work" && dart pub get >> "$log" 2>&1 ); then
    RESULTS+=("FAIL $name — 'dart pub get' failed against hosted dependencies")
    failed=$((failed+1))
    tail -n 15 "$log" | sed 's/^/    /'
    continue
  fi

  if ( cd "$work" && dart test >> "$log" 2>&1 ); then
    RESULTS+=("PASS $name $version")
    passed=$((passed+1))
  else
    RESULTS+=("FAIL $name $version — shipped tests do not pass from the archive")
    failed=$((failed+1))
    tail -n 25 "$log" | sed 's/^/    /'
  fi
done

echo
echo "== published-test summary =="
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
  echo "INCOMPLETE: $passed passed, 0 failed, $skipped skipped."
  exit 0
fi
echo "All $passed published packages run their own tests from the archive."
