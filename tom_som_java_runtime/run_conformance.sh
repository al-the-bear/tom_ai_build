#!/usr/bin/env bash
# Build + run the Java generic-runtime conformance suite against the shared
# language-agnostic corpus. Zero external dependencies: a plain `javac` compile
# and a `java` run of the ConformanceRunner main(), which exits 0 on success.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
corpus="${1:-$here/../tom_som_conformance/corpus}"

rm -rf "$here/build"
mkdir -p "$here/build"
javac -Xlint:all -d "$here/build" "$here"/src/tom_som_runtime/*.java "$here"/tests/ConformanceRunner.java
java -cp "$here/build" ConformanceRunner "$corpus"
