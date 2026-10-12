# Validating a project's spec document

`bin/validate_spec.dart` checks one TomSpecs document — a project's
`*.docspecs.yaml`, or its SOM-rendered `*.md` — against the object model the
package ships, on three tiers. A project needs no runner of its own.

## Running it

```bash
dart run tom_specs_clitool:validate_spec path/to/project.sbp.docspecs.yaml
dart run tom_specs_clitool:validate_spec path/to/project.sbp.md
dart run tom_specs_clitool:validate_spec doc.docspecs.yaml --markdown-out doc.md
dart run tom_specs_clitool:validate_spec doc.docspecs.yaml --json
```

| Option | Meaning |
|--------|---------|
| `--root <type or section id>` | The document root. Default: detected — the key under `document:` in a YAML file (`SBP D00SolutionBlueprint`), the id of the title heading in a markdown rendition (`# <!--[SBP]--> …`). Every one of the fourteen roots is accepted. |
| `--markdown-out <file>` | Also write the document's markdown rendition — the text the schema tier checks. |
| `--json` | One JSON report on stdout instead of the text report. |

Exit codes: `0` all three tiers clean, `1` at least one finding, `2` bad usage
(no document, an unknown `--root`, a file that is not YAML).

## The three tiers

They ask disjoint questions, so all three run every time; a tier that cannot
run — schema and instance after a failed decode — is reported as not run, and
the document does not pass.

| Tier | Question | What reports it |
|------|----------|-----------------|
| `decode` | Does the file load against the model? A YAML key the model does not have, a markdown block that resolves to no section. | `SpecDocument.fromYaml` / `SpecDocument.fromMarkdown` |
| `schema` | Is the document **complete**? Required sections and required form fields, against the generated DocSpecs schema of its root (SOM §13). | `DocSpecsValidator` over the rendition |
| `instance` | Are its **values** valid? Field kinds, enum values, list minima, references into registries (SOM §9). | `validateDocument` |

Neither of the last two implies the other. Removing a required form field moves
the schema tier and not the instance tier — an absent value is not an invalid
one — and a reference into an empty registry passes the schema tier and fails
the instance tier. That is why both run.

## Reading the report

The text report names the root and schema, writes each finding to stderr as
`TIER [code] line/location: message`, and ends with one count per tier:

```text
validate_spec doc.docspecs.yaml — root D00SolutionBlueprint (SBP), schema solution-blueprint
SCHEMA   [missingRequiredField] line 1213 DAENT-CLAS: required form field "aggregateRoot" of "daent-clas-form" is missing
decode   0 finding(s)
schema   1 finding(s)
instance 0 finding(s)
validate_spec: 1 finding(s) — decode 0, schema 1, instance 0
```

A schema finding's line is a line of the **rendition**, not of the YAML; write
it out with `--markdown-out` to follow it.

The `--json` report (format `spec-validation`, version 1) has the shape
`validate_codespecs --json` uses, so a tool reads both the same way: `inputs`,
`root` (type, section id, title, schema id), `passed`, `summary`, `tiers` (per
tier whether it ran and its finding count), `notRun`, and `violations` — per
finding its `tier`, `code`, `severity`, `file`, `line`, `location` and
`message`.

## What it checks against

The model and the fourteen DocSpecs schemas embedded in `tom_som_dart_v0`, at
the version this package resolves. A document written against a newer model
than the one installed reports keys the model does not have; upgrade the
package rather than editing the document.
