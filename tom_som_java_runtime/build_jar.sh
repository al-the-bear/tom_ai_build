#!/usr/bin/env bash
# JDK-only fallback for `mvn package`: compile the generic runtime with `javac`
# and package it into build/tom_som_java_runtime-<version>.jar. Zero external
# dependencies. The version is read from pom.xml so it stays in lockstep with the
# TomSpecs model version (realigned by generate_som's packaging hook).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version="$(grep -o '<version>[^<]*</version>' "$here/pom.xml" | head -1 \
  | sed -E 's/<version>([^<]*)<\/version>/\1/')"

classes="$here/build/classes"
rm -rf "$here/build"
mkdir -p "$classes"

javac -Xlint:all -d "$classes" "$here"/src/tom_som_runtime/*.java

jar --create --file "$here/build/tom_som_java_runtime-$version.jar" \
  -C "$classes" tom_som_runtime

echo "built $here/build/tom_som_java_runtime-$version.jar"
