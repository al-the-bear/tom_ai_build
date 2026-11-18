# Sample — build a specification tool (Java)

**Teaches:** the same as [the Dart sample](../README.md) — reflective access to
the model, generic access to a document, the generated schema, the validation
tiers, and a completeness report built on all of it.
**Phase:** any — tooling.
**Language:** Java, on `tom_som_java_v0` and `tom_som_java_runtime`.

A port of `../bin/build_a_specification_tool.dart`, over the same fixture.

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

Five numbered sections; every number is the Dart sample's. The text is in this
port's own [`expected_output.txt`](expected_output.txt), because it differs from
the Dart sample's:

* where the Dart text names a Dart-only surface, as in the other ports: the
  fixture function is `authorFixture`, the annotation display semantics
  (`kRenderedAnnotations`) are the Dart runtime's, and the Dart text points at a
  Dart example;
* where it names an API, the Java name stands
  (`TomSomV0Meta.D00SolutionBlueprintMeta.informationAndDataModel().dataModel().path`,
  `TomSomV0Meta.D00SolutionBlueprintMetaTree.byId`);
* of the two closed verdict sets, the validation codes are a Java enum
  (`SpecValidationCode`) and the §14 rules a list of string constants
  (`DocSpecsViolation.ALL_RULES`).

`generatedAt` is printed as the snapshot writes it. The facade jar ships the model as a file in the checkout, not inside the jar:
the port reads `tom_som_java_v0/meta/spec_model.meta.json`.
The schema is read the
same way, from `tom_som_java_v0/schemas/solution-blueprint/`.
