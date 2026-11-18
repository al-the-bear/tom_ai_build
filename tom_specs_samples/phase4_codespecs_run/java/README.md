# Sample — a Phase 4 CodeSpecs run (Java)

**Teaches:** the first two stages of [the Dart sample](../README.md) — the
starting prompt's quality gate (passing and rejecting) and the extract
generator — on the same specification.
**Phase:** 4 (CodeSpecs) of `tom_specs_project_flow.md`.
**Language:** Java, on `tom_som_java_v0` and `tom_som_java_runtime`.

The Java runtime carries the gate (`CodeSpecsGate`, checks A1–A5) and the
extract generator, as all nine runtimes do. Stages 3 and 4 are not here: the
authoring agent writes the IR, and the Dart tools map and validate it
(`tomspecs :ir-map`, `tomspecs :codespecs-validate`). The Dart sample shows them.
This port says so where they would be, rather than printing what it did not run.

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

The model, the Solution Blueprint schema and the area catalogue are read from
the checkout: `tom_som_java_v0/meta/spec_model.meta.json`,
`tom_som_java_v0/schemas/solution-blueprint/` and
`tom_specs_model/generated-doc/codespecs/codespecs_areas.json` (the Dart package
`tom_specs_model` ships the catalogue with an accessor; the Java runtime has none).

## What you should see

Variant A passing the gate and producing 27 extracts (3 populated), variant B
rejected with six findings. The text is in this port's own
[`expected_output.txt`](expected_output.txt): stages 1 and 2 and variant B are
the Dart sample's lines, and stages 3 and 4 are replaced by the note above.
The 54 extract files in `build/codespecs_extracts/` are byte for byte the ones
the Dart sample writes.
