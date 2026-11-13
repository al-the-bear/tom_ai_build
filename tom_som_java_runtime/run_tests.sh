#!/usr/bin/env bash
# Runs everything hand-authored in this package: the shared-corpus conformance
# runner plus every `*Test.java` under tests/. Zero external dependencies: a
# plain `javac` compile and a `java` run of each dependency-free `main()`,
# which exits 0 on success and 1 on failure.
#
# The test list is derived from the tests/ directory rather than hand-listed, so
# a new test file is picked up without editing this script. `run_conformance.sh`
# runs only the conformance runner; this is the full run.
#
# Exit 0 == all green. Every test runs even when an earlier one fails, so one
# invocation reports the full picture rather than only the first breakage.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DocSpecsValidatorTest addresses the corpus and the sibling v0 packages by the
# relative path `../tom_som_...`, so the run has to happen from the project
# directory — the same cd every other package's runner does.
cd "$here"

# testkit (`testkit :baseline` / `:test`) sets TESTKIT_REPORT: every test below
# then adds one result line to that file (tom_test_kit's line protocol, one
# JSON object per line). tk_result also folds the test's exit code into rc.
tk_result() { # <test name> <exit code>
  if [ -n "${TESTKIT_REPORT:-}" ]; then
    local result=ok
    [ "$2" -eq 0 ] || result=fail
    printf '{"test":"%s","result":"%s"}\n' "$1" "$result" >>"$TESTKIT_REPORT"
  fi
  [ "$2" -eq 0 ] || rc=1
}
corpus="${1:-$here/../tom_som_conformance/corpus}"

rm -rf "$here/build"
mkdir -p "$here/build"
javac -Xlint:all -d "$here/build" "$here"/src/tom_som_runtime/*.java \
  "$here"/tests/*.java || exit 1

rc=0
echo "== ConformanceRunner =="
java -cp "$here/build" ConformanceRunner "$corpus"
tk_result "tests/ConformanceRunner.java" $?

for f in "$here"/tests/*Test.java; do
  cls="$(basename "$f" .java)"
  echo "== $cls =="
  java -cp "$here/build" "$cls"
  tk_result "tests/$cls.java" $?
done

if [ "$rc" -eq 0 ]; then
  echo "All Java runtime tests passed."
fi
exit "$rc"
