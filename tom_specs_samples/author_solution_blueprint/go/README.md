# Sample — author a Solution Blueprint (Go)

**Teaches:** the same as [the Dart sample](../README.md) — authoring a TomSpecs
specification end to end through the typed facade: write, serialise both
renditions, round-trip, validate, and read a real diagnostic.
**Phase:** 2 (Solution Blueprint) of `tom_specs_project_flow.md`.
**Language:** Go, on `tom_som_go_v0` and `tom_som_go_runtime`.

A port of `../bin/author_solution_blueprint.dart`, step for step.

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

Exactly what the Dart sample prints: its [`expected_output.txt`](../expected_output.txt),
which the samples driver compares this port against too. The two renditions are
written to `build/`, byte for byte the ones the Dart sample writes.

The Go facade ships the model as a file, not as an accessor: the port reads
`tom_som_go_v0/meta/spec_model.meta.json` from the checkout, found relative to
`main.go`, so it runs from any working directory.
