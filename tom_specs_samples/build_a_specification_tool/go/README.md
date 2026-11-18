# Sample — build a specification tool (Go)

**Teaches:** the same as [the Dart sample](../README.md) — reflective access to
the model, generic access to a document, the generated schema, the validation
tiers, and a completeness report built on all of it.
**Phase:** any — tooling.
**Language:** Go, on `tom_som_go_v0` and `tom_som_go_runtime`.

A port of `../bin/build_a_specification_tool.dart`, over the same fixture.

## Prerequisites

* Go 1.21 or later (`go version`).
* A checkout of `tom_ai/ai_build`. The Go modules, `tom_som_go_runtime` and
  `tom_som_go_v0`, are **not updated on the module proxy** (the non-Dart
  runtimes are not published; the proxy holds v1.0.0, which predates this
  model), so `go.mod` points both module paths at the checkout with `replace`
  directives (`../../../tom_som_go_runtime`, `../../../tom_som_go_v0`).
  `go run` builds them from there and downloads nothing; neither module has
  dependencies of its own.

## Run it

```bash
go run .
```

## What you should see

Five numbered sections; every number is the Dart sample's. The text is in this
port's own [`expected_output.txt`](expected_output.txt), because it differs from
the Dart sample's:

* where the Dart text names a Dart-only surface, as in the other ports: the
  fixture function is `authorFixture`, the annotation display semantics
  (`kRenderedAnnotations`) are the Dart runtime's, and the Dart text points at a
  Dart example;
* where it names an API, the Go name stands (`CheckStamp`, `ValidateDocument`,
  `D00SolutionBlueprintMeta.InformationAndDataModel().DataModel().Path`,
  `ByID`, `ByPath`);
* Go has no enums: the two closed verdict sets are the runtime's lists of string
  constants, `SpecValidationAllCodes` and `DocSpecsAllRules`;
* an annotation's arguments are a Go map, which has no order, so their names
  are printed sorted (`@Document(description, name)`).

`generatedAt` is printed as the snapshot writes it. `CheckStamp` takes its age
threshold as an argument (Go has no default arguments); the port passes 30 days,
the other runtimes' default. The Go facade ships the model as a file, not as an accessor: the port reads
`tom_som_go_v0/meta/spec_model.meta.json` from the checkout, found relative to
`main.go`, so it runs from any working directory. The schema is read the same way, from
`tom_som_go_v0/schemas/solution-blueprint/`.
