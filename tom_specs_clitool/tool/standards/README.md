# The standards' meta-schemas

The official meta-schemas the output of `irspecs emit` is validated against
(`tom_core_codespecs/doc/irspecs_ir.md` §10), vendored so the test runs
offline and against a fixed version. They are copied **unchanged** from their
publishers; a new version is a new folder, never an edit.

| Folder | Standard | Version | Source | Retrieved |
|--------|----------|---------|--------|-----------|
| `openapi-3.1/` | OpenAPI | 3.1 (schema 2022-10-07) | `https://spec.openapis.org/oas/3.1/schema/2022-10-07` (`schema-2022-10-07.json`), `…/oas/3.1/schema-base/2022-10-07` (`schema-base-2022-10-07.json`), `…/oas/3.1/dialect/base` (`dialect-base-2022-10-07.json`), `…/oas/3.1/meta/base` (`meta-base-2022-10-07.json`) | 2026-11-13 |
| `jsonschema-2020-12/` | JSON Schema | 2020-12 | `https://json-schema.org/draft/2020-12/schema` (`schema.json`) and its vocabularies `https://json-schema.org/draft/2020-12/meta/<name>` (`meta/<name>.json`: core, applicator, unevaluated, validation, meta-data, format-annotation, content) | 2026-11-13 |
| `asyncapi-3.0.0/` | AsyncAPI | 3.0.0 | `https://raw.githubusercontent.com/asyncapi/spec-json-schemas/master/schemas/3.0.0.json` (`asyncapi-3.0.0.json`, the bundled schema with every binding inlined) | 2026-11-13 |

Each file is identified by its own `$id`; `validate_standard.py` registers
every file here under it, so no reference leaves this folder.

**ICU MessageFormat has no meta-schema.** Its catalogue is checked by the
syntax parser in `lib/src/irspecs/emitters/icu_emitter.dart`
(`icuSyntaxErrors`, the ICU User Guide's MessageFormat syntax).

## `validate_standard.py`

```text
python3 tool/standards/validate_standard.py <openapi|jsonschema|asyncapi> <document.json>
```

Validates the document with Python's `jsonschema` (the version every fleet host
carries for the todo guard suite): OpenAPI against `schema-base` — which checks
the document and, through the OAS dialect, every Schema Object in it — with the
2020-12 validator, JSON Schema against the 2020-12 meta-schema, AsyncAPI against
the 3.0.0 schema with the draft-07 validator it is written for. Exits `0` when
valid and `1` with every error on stdout otherwise, `2` on bad usage.
