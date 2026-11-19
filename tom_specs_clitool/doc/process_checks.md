# Running the process checks: the `tomspecs :spec-*` commands

The `tomspecs :spec-*` commands run the TomSpecs process checks on any project's specification
document: what a project runs at a gate beyond the three validation tiers. Each
check is a command; the checks themselves are library functions of
`package:tom_som_dart_runtime/spec_checks.dart`, and these commands are the thin
CLI over them.

```bash
dart pub global activate tom_specs_clitool
dart pub global run tom_specs_clitool:tomspecs :<check> <arguments>
```

Inside this repository, `dart run tom_specs_clitool:tomspecs` from the
package folder does the same.

## The checks

| Check | Arguments | What it answers |
|-------|-----------|-----------------|
| `:spec-render` | `<doc.tomspecs.yaml> [<rendition.md>]` | Decode, DocSpecs schema and instance tiers; with a second path also writes the markdown rendition. Findings go to stderr, the summaries to stdout. |
| `:spec-import-answers` | `[--dry-run] [--allow-other-edits] <doc.tomspecs.yaml> <rendition.md>` | Imports the answers typed into the rendition into the YAML, in place and verified, then validates and regenerates the rendition. A rendition that differs in more than answers is refused (exit 2). An answer keeps the label it was written with: `**Answer:**`, or the owner's `**Answer (<time>):**`. |
| `:spec-accept-marks` | `<doc.tomspecs.yaml> [--under <ID>/<ID>] [--write]` | Accepts every inline change mark in place, keeping the file's layout, and checks every value against the runtime's `acceptAllMarks` before `--write` writes. `--under` limits it to one section (the section ids of the YAML keys). For a document too large for a whole-file re-encode. |
| `:spec-required-fields` | `<doc.tomspecs.yaml>` | Every form holds the fields the model marks required; its int, bool and enum fields hold values of their type. |
| `:spec-question-register` | `<doc.tomspecs.yaml> <index.md> [--write]` | A question index file against the document's question blocks; `--write` rewrites its status counts, the sentence below them and the id range. |
| `:spec-feature-register` | `<sbp.tomspecs.yaml>` | Every functional requirement linked by exactly one feature; every linked id and prototype feature resolving; the stated total matching. |
| `:spec-idea-coverage` | `<project_idea.md> <sbp.tomspecs.yaml> [--exclusions <yaml>] [--all]` | Every Project Idea id cited by a requirement's source, carried by a covered id, or excluded by a record. `--all` lists the covered ids too. |
| `:spec-authorization` | `<sbp.tomspecs.yaml>` | Operations, the role matrix, screens and use cases agree. |
| `:spec-coverage` | `<sample.tomspecs.yaml> <sbp.tomspecs.yaml> [<old.tomspecs.yaml>] [--tsv <out.tsv>]` | How much of the model the document fills, per configured row, and the class of every empty section. |
| `:spec-fill-frem` | `<doc.tomspecs.yaml> [--dry-run] [--rendition <doc.tomspecs.md>]` | Fills every functional requirement's `FREM` (version, last modified, modified by) from the document's git history; see [Filling FREM from git](#filling-frem-from-git). |

Exit codes: `0` clean, `1` findings, `2` usage error (or a refused import).
The model is the one the installed `tom_som_dart_v0` embeds; the document's
root is read from the document.

## Filling FREM from git

Every git revision of a document has its own document revision: a commit that
changes the document adds its entry to the revision list (`RVENT-REVS-LST`). The
list therefore maps document revisions to git revisions; an entry's git revision
is the commit that added it. `:spec-fill-frem` reads that mapping:

1. It walks the document's commits (`git log --follow`), oldest first, and the
   working tree last when it differs from the last commit.
2. For each functional requirement it compares the requirement's section, found
   by its section id in each version's YAML, and takes the last version that
   changed it. Key order and the requirement's own `FREM` are left out of the
   comparison, so a reordered model or an earlier fill is not a change.
3. It writes that version's document revision into `FREM`: `version`,
   `lastModified` (the entry's date) and `modifiedBy` (its author).

The write is staged: the new text goes to a sibling `<doc>.fill-frem.stage`,
is read back and renamed over the document. The values are rewritten in place
when every `FREM` already holds its three fields as block scalars; otherwise the
document is re-encoded. Before anything is written, the new text is decoded and
compared with the document plus the fills, so no other value can change.
`--dry-run` reports and writes nothing; `--rendition` also writes the markdown
rendition.

Each requirement gets one report line: `FREM` when its values change, `same`
when they are already right. Findings exit `1`; the fills are written all the
same:

- `REVISION`: a commit changed the document without adding a revision entry.
  Its changes are attributed to the newest entry it holds.
- `NOREVISION`: a requirement's last change is in a version without a revision
  list. Its `FREM` is left as it is.
- `DUPLICATE`: a requirement's section id occurs more than once.

A file that is not committed to a git repository is a usage error (exit `2`).

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
