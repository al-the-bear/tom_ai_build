# Sample — a Phase 4 CodeSpecs run (Go)

**Teaches:** the first two stages of [the Dart sample](../README.md) — the
starting prompt's quality gate (passing and rejecting) and the extract
generator — on the same specification.
**Phase:** 4 (CodeSpecs) of `tom_specs_project_flow.md`.
**Language:** Go, on `tom_som_go_v0` and `tom_som_go_runtime`.

The Go runtime carries the gate (`CodeSpecsGate`, checks A1–A5) and the
extract generator, as all nine runtimes do. Stages 3 and 4 are not here: the
authoring agent writes the IR, and the Dart tools map and validate it
(`tomspecs :ir-map`, `tomspecs :codespecs-validate`). The Dart sample shows them.
This port says so where they would be, rather than printing what it did not run.

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

The model, the Solution Blueprint schema and the area catalogue are read from
the checkout, found relative to `main.go`:
`tom_som_go_v0/meta/spec_model.meta.json`,
`tom_som_go_v0/schemas/solution-blueprint/` and
`tom_specs_model/generated-doc/codespecs/codespecs_areas.json` (the Dart package
`tom_specs_model` ships the catalogue with an accessor; the Go runtime has none).

## What you should see

Variant A passing the gate and producing 27 extracts (3 populated), variant B
rejected with six findings. The text is in this port's own
[`expected_output.txt`](expected_output.txt): stages 1 and 2 and variant B are
the Dart sample's lines, and stages 3 and 4 are replaced by the note above.
The 54 extract files in `build/codespecs_extracts/` are byte for byte the ones
the Dart sample writes.
