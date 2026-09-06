# The emitted CodeSpecs trio — Phase 4 output

Phase 4's output for this walkthrough: a skeleton that **compiles but does not
execute**. It is not this sample's source, and it is excluded from
`dart analyze` by `../analysis_options.yaml` — the reasoning is in that file.

Phase 4 always emits **three** projects whatever the specification says
(`codespecs_mapping.md` §4.2), so that the unit Phases 5 and 6 consume has one
shape rather than a shape that depends on its input:

| Directory | Package | Holds |
|-----------|---------|-------|
| `shared/` | `<app>_codespec_shared` | Types both halves must agree on |
| `client/` | `<app>_codespec_client` | Screens, forms, actions, view state |
| `server/` | `<app>_codespec_server` | Entities, repositories, service units |

Only `server/` holds code here. This walkthrough's Phase-2 and Phase-3
documents write an information model and a requirement; they specify no screens
and no server operations, so the client project has nothing to hold and the
shared project's one candidate — the CE-API wire DTO — is derived from
operations that were never specified.

`validation_report.txt` is the recorded output of
`tom_specs_clitool/bin/validate_codespecs.dart` over this trio, kept current by
`../tool/validate.sh`. The two invocations it records are what make the
`codespecs_mapping.md` §9.6 self-sufficiency property checkable rather than
asserted: **checks 35 and 36
only run when `--extracts` is given**, and they are the two that compare the
trio's back-links against what the specification actually routed, in both
directions.

`phase4_codespecs_run` beside this sample walks the whole of Phase 4 — the
two-pass production model, the gate, the extract generator and the authoring
agent. This walkthrough carries the output and measures the property; it does
not repeat that.
