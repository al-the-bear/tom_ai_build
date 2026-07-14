#!/usr/bin/env bash
# Build + run the Java runtime unit tests. Zero external dependencies: a plain
# `javac` compile and a `java` run of each dependency-free test `main()`, which
# exits 0 on success and 1 on failure.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rm -rf "$here/build"
mkdir -p "$here/build"
javac -Xlint:all -d "$here/build" "$here"/src/tom_som_runtime/*.java \
  "$here"/tests/SomFacadeTest.java "$here"/tests/SomListContentTest.java \
  "$here"/tests/SomCanHaveContentTest.java "$here"/tests/SpecItem12Test.java \
  "$here"/tests/SpecMetaTest.java "$here"/tests/SpecDocumentYamlTest.java
java -cp "$here/build" SomFacadeTest
java -cp "$here/build" SomListContentTest
java -cp "$here/build" SomCanHaveContentTest
java -cp "$here/build" SpecItem12Test
java -cp "$here/build" SpecMetaTest
java -cp "$here/build" SpecDocumentYamlTest
