# The emitted CodeSpecs trio

This directory is Phase 4's **output** — what the authoring agent wrote in
stage 3 of `bin/phase4_codespecs_run.dart`, and what
`tom_specs_clitool/bin/validate_codespecs.dart` checks in stage 4. It is not
this sample's source, and it is excluded from `dart analyze` by
`../analysis_options.yaml`; the reasoning is in that file.

Phase 4 always emits **three** projects, whatever the specification says
(`codespecs_mapping.md` §4.2):

| Directory | Package | Holds |
|-----------|---------|-------|
| `shared/` | `<app>_codespec_shared` | Types both halves must agree on |
| `client/` | `<app>_codespec_client` | Screens, forms, actions, view state |
| `server/` | `<app>_codespec_server` | Entities, repositories, service units, handlers |

In this run only `server/` holds code. The sample's specification writes an
information model and nothing else — no screens, no operations, no jobs — so
the client project has nothing to hold and the shared project's one candidate,
the CE-API wire DTO, is *derived* from server operations that were never
specified (`codespecs_derivation_contract.md` §3.2.11). Both directories exist
anyway: the trio is the unit Phase 5 and Phase 6 consume, and a run that
emitted two projects would be a run whose shape depended on its input.

`validation_report.txt` is stage 4's recorded output, kept current by
`../tool/validate.sh`.
