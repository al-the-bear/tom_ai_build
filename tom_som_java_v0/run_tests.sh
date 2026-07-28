#!/usr/bin/env bash
# Runs everything hand-authored in this generated tree:
#   - the behavioural test        (tests/GeneratedModelTest.java)
#   - the metadata agreement test (tests/MetaAgreementTest.java)
#   - the three samples           (examples/ATypedAccess.java, B..., C...)
# all compiled against the generated typed module + the generic runtime. Zero
# external deps: a plain `javac` compile and a `java` run.
#
# The generic runtime location is read from the generated build manifest
# (`tom_som_build.json` → runtimeSourcePath, relative to this project) so the
# script is portable across checkouts. The test list is derived from the tests/
# directory rather than hand-listed, so a new test file is picked up without
# editing this script.
#
# Mirrors the C / C++ v0 runners: exit 0 == all green. It cd's to its own
# directory so the meta-data default path used by sample (C) resolves.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

runtime_rel="$(grep -o '"runtimeSourcePath"[[:space:]]*:[[:space:]]*"[^"]*"' \
  "$here/tom_som_build.json" | sed -E 's/.*"([^"]*)"$/\1/')"
runtime="$(cd "$here/$runtime_rel" && pwd)"

rm -rf "$here/build"
mkdir -p "$here/build"

# Compile everything together: the typed module is found on the source path, and
# javac pulls in the runtime sources it depends on automatically.
javac -d "$here/build" -sourcepath "$here/src:$runtime" \
  "$here"/tests/*.java "$here"/examples/*.java "$here"/tool/*.java || exit 1

rc=0
for f in "$here"/tests/*Test.java; do
  cls="$(basename "$f" .java)"
  echo "== $cls =="
  java -cp "$here/build" "$cls" || rc=1
done

for sample in ATypedAccess BGenericDocument CReflectionMetadata; do
  echo "== sample: $sample =="
  java -cp "$here/build" "$sample" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then
  echo "All Java v0 tests and samples passed."
fi
exit "$rc"
