#!/usr/bin/env bash
# Compile the generated typed module + the generic runtime + the hand-authored
# behavioural test and samples, then run the behavioural test (exit 0 on
# success). Zero external deps: a plain `javac` compile and a `java` run.
#
# The generic runtime location is read from the generated build manifest
# (`tom_som_build.json` → runtimeSourcePath, relative to this project) so the
# script is portable across checkouts.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

runtime_rel="$(grep -o '"runtimeSourcePath"[[:space:]]*:[[:space:]]*"[^"]*"' \
  "$here/tom_som_build.json" | sed -E 's/.*"([^"]*)"$/\1/')"
runtime="$(cd "$here/$runtime_rel" && pwd)"

rm -rf "$here/build"
mkdir -p "$here/build"

# Compile everything together: the typed module is found on the source path, and
# javac pulls in the runtime sources it depends on automatically.
javac -d "$here/build" -sourcepath "$here/src:$runtime" \
  "$here"/tests/*.java "$here"/examples/*.java "$here"/tool/*.java

java -cp "$here/build" GeneratedModelTest
java -cp "$here/build" MetaAgreementTest
