# Sample — author a Solution Blueprint (Java)

**Teaches:** the same as [the Dart sample](../README.md) — authoring a TomSpecs
specification end to end through the typed facade: write, serialise both
renditions, round-trip, validate, and read a real diagnostic.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** Java, on `tom_som_java_v0` and `tom_som_java_runtime`.

A port of `../bin/author_solution_blueprint.dart`, step for step.

## Prerequisites

* JDK 17 or later and Maven 3.9 or later (`mvn -v`).
* A checkout of `tom_ai/ai_build`. The Java artifacts,
  `io.github.al-the-bear:tom_som_java_runtime` and
  `io.github.al-the-bear:tom_som_java_v0`, are **not on Maven Central** (the
  non-Dart runtimes are not published), so they come from the local Maven
  repository: install both from the checkout first, the runtime before the
  facade that depends on it. Neither has dependencies of its own.

## Run it

```bash
(cd ../../../tom_som_java_runtime && mvn -q install)
(cd ../../../tom_som_java_v0 && mvn -q install)
mvn -q compile exec:java
```

The installs are needed once per model version; `run_all_samples.sh` does them
once per run. `exec:java` comes from `exec-maven-plugin`, which Maven fetches
like any other plugin the first time. The pom passes the checkout to the program
as the system property `tomspecs.checkout` (`${project.basedir}/../../..`), so it
finds the files it reads wherever Maven is started.

## What you should see

Exactly what the Dart sample prints: its [`expected_output.txt`](../expected_output.txt),
which the samples driver compares this port against too. The two renditions are
written to `build/`, byte for byte the ones the Dart sample writes.

The facade jar ships the model as a file in the checkout, not inside the jar:
the port reads `tom_som_java_v0/meta/spec_model.meta.json`.
