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
corpus="${1:-$here/../tom_som_conformance/corpus}"

rm -rf "$here/build"
mkdir -p "$here/build"
javac -Xlint:all -d "$here/build" "$here"/src/tom_som_runtime/*.java \
  "$here"/tests/*.java || exit 1

rc=0
echo "== ConformanceRunner =="
java -cp "$here/build" ConformanceRunner "$corpus" || rc=1

for f in "$here"/tests/*Test.java; do
  cls="$(basename "$f" .java)"
  echo "== $cls =="
  java -cp "$here/build" "$cls" || rc=1
done

if [ "$rc" -eq 0 ]; then
  echo "All Java runtime tests passed."
fi
exit "$rc"
