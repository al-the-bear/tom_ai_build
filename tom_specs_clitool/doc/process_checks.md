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
| `:spec-readable` | `<doc.tomspecs.yaml> [<out.readable.md>] [-drop:<names>] [-unmark:<names>] [-appendix:<names>] [--appendix-references] [--heading-divs]` or `--merge-onto <doc.tomspecs.yaml> <edited.readable.md> [--base <file>] [switches] [--write]` | Writes a readable rendition with the chosen kinds dropped, unmarked or moved to an appendix, or merges an edited one back onto the document; see [Readable renditions and the merge back](#readable-renditions-and-the-merge-back). |
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

## Readable renditions and the merge back

`:spec-readable` (the check `render`) writes a **readable rendition**: the
document's Markdown with the reading notation and the review annotations
stripped as asked (SOM §11.10). Stakeholders read and correct it, and the
corrections are merged back into the document of record.

```text
tomspecs :spec-readable <doc.tomspecs.yaml> [<out.readable.md>] [-drop:<names>] [-unmark:<names>]
         [-appendix:<names>] [--appendix-references] [--heading-divs]
tomspecs :spec-readable --merge-onto <doc.tomspecs.yaml> <edited.readable.md> [--base <file>]
         [switches] [--write]
```

**The switches.** The names are the notation kinds `provenance`, `trace`,
`editorial` and `aside`, plus `comments` for the review annotations; `all`
stands for every one of them. Several names are comma-separated
(`-drop:trace,comments`), and `--drop=<names>` is the same as `-drop:<names>`.

| Switch | Does |
|--------|------|
| `-drop:<names>` | Removes the marked blocks and spans of those kinds, text included. `comments` accepts the inline marks and removes the comment and question blocks. |
| `-unmark:<names>` | Removes the markers and keeps the text (`(-> C2.1)` reads `(C2.1)`). `comments` cannot be unmarked. |
| `-appendix:<names>` | Moves the blocks and spans of those kinds into an appendix *Notes* at the end, numbered, under the title of their section. |
| `--appendix-references` | Leaves a link `[n]` in each place, to its appendix entry (only with `-appendix:`). |
| `--heading-divs` | Writes sections below level 6 as styled divs instead of headings. |

A name in two lists, an unknown name, `comments` in `-unmark:` or `-appendix:`,
and `--appendix-references` without `-appendix:` are usage errors. `refs`,
`records` and the tables are content and never stripped.

**The stakeholder preset** is `-drop:all --heading-divs`: the text alone, without
provenance, traces, editorial notes, asides or review annotations, and with deep
sections as styled divs.

```text
tomspecs :spec-readable tom_uam.sbp.tomspecs.yaml tom_uam.sbp.readable.md -drop:all --heading-divs
```

### Writing the rendition

The first form writes the rendition to the path given, or to stdout without one.
Its second line is the **readable header**, which records the switches and the
document it was made from:

```text
<!-- readable: drop=provenance,trace,editorial,aside,comments; headings=divs; of=tom_uam.sbp.tomspecs.yaml@<revision>; commit=<sha> -->
```

`<revision>` is the sha256 of the document's text. `commit` is the last commit
that changed the document, with `+dirty` when the file differs from it; it is
left out when the document is not in a git repository.

The report gives the header, one line per kind (`trace: 4 dropped, 0 unmarked,
0 moved`), the values kept unstripped because stripping them would add a
finding (the emptying rule), and a summary line. Without an output path the
report goes to stderr, so stdout holds the rendition alone. Writing over the
document or over its own `<doc>.tomspecs.md` is a usage error: the readable
rendition is a separate file, by convention `<doc>.readable.md`.

### Merging it back

The second form reads the edited rendition and merges its changed values onto
the document. The switches come from the readable header; switches given on the
command line must agree with it, or stand in for a missing header. A rendition
with neither is a usage error.

- **Only text is merged.** Each changed value (content, a form field, a
  headline) is merged with the pieces the strip removed put back in place
  (`MERGED <path> [/ <field>] — n pieces put back`; a piece placed next to an
  edit adds a `PLACED` line). An added, removed or moved section, a changed
  list, `codeSpec` or `units` is refused (`REFUSED`): structure is changed in
  the document of record.
- **A stale document** is one whose revision moved since the export. The merge
  then reads the document as it was at the export, from git
  (`git show <commit>:<path>`, the header's commit), or from the file given with
  `--base`, and merges three ways. A value changed both in the document and in
  the rendition is a conflict. Without the header's commit (no git repository,
  or `+dirty`) and without `--base`, the stale merge is refused.
- **All or nothing.** Any conflict (`CONFLICT`, with the three excerpts O / B /
  E) or refusal writes nothing.
- **Dry run by default.** Without `--write` the merge is planned and reported,
  and nothing is written. With `--write`, the YAML is rewritten in place (only
  the block scalars of the merged values, the writer `:spec-import-answers`
  uses) through a staged sibling `<doc>.render.stage` that is read back and
  renamed over the document. The document's `<doc>.tomspecs.md` is then
  regenerated. A value with no block scalar of its own yet, such as a form
  field the reader filled in, makes the whole document re-encoded instead; the
  `yaml` line says which. Either way the new text must decode to the merged
  document before it is written.

The merge itself is the runtime's `SpecStripMerge.merge`
(`package:tom_som_dart_runtime`, in TypeScript too), so the same rules apply
wherever the rendition is merged.

Exit codes: `0` merged, or nothing to merge; `1` conflicts or refusals (nothing
written), or a rendition that could not be made; `2` usage.

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
