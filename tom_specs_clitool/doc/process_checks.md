# Running the process checks: `spec_checks`

`spec_checks` runs the TomSpecs process checks on any project's specification
document: what a project runs at a gate beyond the three validation tiers. Each
check is a subcommand; the checks themselves are library functions of
`package:tom_som_dart_runtime/spec_checks.dart`, and this command is the thin
CLI over them.

```bash
dart pub global activate tom_specs_clitool
dart pub global run tom_specs_clitool:spec_checks <check> <arguments>
```

Inside this repository, `dart run tom_specs_clitool:spec_checks` from the
package folder does the same.

## The checks

| Check | Arguments | What it answers |
|-------|-----------|-----------------|
| `validate` | `<doc.docspecs.yaml> [<rendition.md>]` | Decode, DocSpecs schema and instance tiers; with a second path also writes the markdown rendition. Findings go to stderr, the summaries to stdout. |
| `import-answers` | `[--dry-run] [--allow-other-edits] <doc.docspecs.yaml> <rendition.md>` | Imports the answers typed into the rendition into the YAML, in place and verified, then validates and regenerates the rendition. A rendition that differs in more than answers is refused (exit 2). An answer keeps the label it was written with: `**Answer:**`, or the owner's `**Answer (<time>):**`. |
| `accept-marks` | `<doc.docspecs.yaml> [--under <ID>/<ID>] [--write]` | Accepts every inline change mark in place, keeping the file's layout, and checks every value against the runtime's `acceptAllMarks` before `--write` writes. `--under` limits it to one section (the section ids of the YAML keys). For a document too large for a whole-file re-encode. |
| `required-fields` | `<doc.docspecs.yaml>` | Every form holds the fields the model marks required; its int, bool and enum fields hold values of their type. |
| `question-register` | `<doc.docspecs.yaml> <index.md> [--write]` | A question index file against the document's question blocks; `--write` rewrites its status counts, the sentence below them and the id range. |
| `feature-register` | `<sbp.docspecs.yaml>` | Every functional requirement linked by exactly one feature; every linked id and prototype feature resolving; the stated total matching. |
| `project-idea-coverage` | `<project_idea.md> <sbp.docspecs.yaml> [--exclusions <yaml>] [--all]` | Every Project Idea id cited by a requirement's source, carried by a covered id, or excluded by a record. `--all` lists the covered ids too. |
| `authorization` | `<sbp.docspecs.yaml>` | Operations, the role matrix, screens and use cases agree. |
| `coverage` | `<sample.docspecs.yaml> <sbp.docspecs.yaml> [<old.docspecs.yaml>] [--tsv <out.tsv>]` | How much of the model the document fills, per configured row, and the class of every empty section. |

Exit codes: `0` clean, `1` findings, `2` usage error (or a refused import).
The model is the one the installed `tom_som_dart_v0` embeds; the document's
root is read from the document.

## The project's data: `<spec-root>/checks/`

What a check needs that the document does not state as data is the project's,
kept in its spec root's `checks/` folder and reviewed like code:

| File | Read by | Holds |
|------|---------|-------|
| `authorization_cross_check.yaml` | `authorization` (required) | The role model: `platformOnlyKeys`, `roleKeys`, `handlerRoles`, `actorRoles`, `otherActorOperations`, `pendingQuestions` |
| `coverage_rows.yaml`, `coverage_reasons.yaml` | `coverage` (required) | The rows of the coverage table and the rules classing an empty section |
| `project_idea_coverage.yaml` | `project-idea-coverage` (optional) | `exclusions`: each Project Idea id not cited, with its `reason` and the `record` that excludes it |
| `question_register.yaml` | `question-register` (optional) | `prefixes` (the question-id prefixes), `groups` (one count column each: `key`, `label` with `{max}`, `prefix`, `from`, `to`) and `statuses` (`key`, `label`, `waiting`) |

Without `question_register.yaml` every upper-case prefix is a question id, each
prefix has one column, and the statuses are `open` (waiting), `answered`,
`obsolete` and `duplicate`.

The spec root is the nearest folder above the document holding a `checks/`
folder (up to four levels), else the document folder's parent; `--spec-root
<dir>` names it.
