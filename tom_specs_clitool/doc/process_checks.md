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
| `:spec-readable` | `<doc.tomspecs.yaml> [<out.readable.md>] [-drop:<names>] [-unmark:<names>] [-appendix:<names>] [--appendix-references] [--heading-divs]` or `--merge-onto <doc.tomspecs.yaml> <edited.readable.md> [--base <file>] [switches] [--write]` | Writes a readable rendition with the chosen kinds dropped, unmarked or moved to an appendix, or merges an edited one back onto the document; see [Readable renditions and the merge back](#readable-renditions-and-the-merge-back); `tom_md_export` turns it into a PDF or an HTML page ([Exporting it as PDF or HTML](#exporting-it-as-pdf-or-html)). |
| `:spec-import-answers` | `[--dry-run] [--allow-other-edits] <doc.tomspecs.yaml> <rendition.md>` | Imports the answers typed into the rendition into the YAML, in place and verified, then validates and regenerates the rendition. A rendition that differs in more than answers is refused (exit 2). An answer keeps the label it was written with: `**Answer:**`, or the owner's `**Answer (<time>):**`. |
| `:spec-accept-marks` | `<doc.tomspecs.yaml> [--under <ID>/<ID>] [--write]` | Accepts every inline change mark in place, keeping the file's layout, and checks every value against the runtime's `acceptAllMarks` before `--write` writes. `--under` limits it to one section (the section ids of the YAML keys). For a document too large for a whole-file re-encode. |
| `:spec-mark-secondary` | `<doc.tomspecs.yaml> [--under <ID>/<ID>] [--kinds provenance,trace,editorial,references] [--reflow] [--all] [--write]` | Writes the secondary prose (provenance notes, trace citations, the provenance-notes preamble, section references) in the reading notation, in place; a dry run without `--write`. See [Marking secondary prose](#marking-secondary-prose). |
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

### Exporting it as PDF or HTML

A stakeholder gets a PDF or an HTML page, made in two commands: the readable
rendition with the stakeholder preset, then the export of the package
[tom_md_export](../../tom_md_export/README.md), which reads it as it stands and
adds nothing:

```text
tomspecs :spec-readable <doc>.tomspecs.yaml <spec-root>/exports/<doc>.readable.md -drop:all --heading-divs
dart run tom_md_export:md_export <spec-root>/exports/<doc>.readable.md -o <spec-root>/exports/<doc>.pdf
dart run tom_md_export:md_export <spec-root>/exports/<doc>.readable.md -o <spec-root>/exports/<doc>.html
```

`-drop:all` drops the four secondary kinds and the review annotations;
`--heading-divs` writes the headings below level six as styled divs, which both
exports turn into headings. Other switch sets are the reader's choice:
`-unmark:` keeps the notes as plain text, every kind kept shows each in its
style (smaller and muted in the PDF, a collapsed `<details>` in the HTML).

The PDF is set by Typst, the HTML by the MD Browser's own renderer in Node; how
to get Typst and what the export needs is in the package's README. Tom UAM's
Information Model (about 146,000 lines readable) takes about 22 seconds to PDF
and 14 seconds to HTML.

**Where an export is written:** where the caller names it. The documented place
is `<spec-root>/exports/`, which the project gitignores: an export is rebuilt
from the document of record whenever it is needed (the readable header names
the source and its commit), and the user decides which exports to archive. A
person starts it, or an agent asked to; nothing runs it on its own.

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

## Marking secondary prose

`:spec-mark-secondary` (the check `mark-secondary`) writes a document's
secondary prose in the reading notation (the DocSpecs specification's *Reading
Notation*), so that every rendition, the MD Browser and `:spec-readable` can fold
or drop it. It is run once per document, when the document is brought into the
new layout; text written afterwards is marked by its author.

```text
tomspecs :spec-mark-secondary <doc.tomspecs.yaml> [--under <ID>/<ID>]
         [--kinds provenance,trace,editorial,references] [--reflow] [--all] [--write]
```

It works on the YAML in place, like `:spec-accept-marks`: only the block scalars
it changes are rewritten, and every other byte of the file stays. A one-line
scalar it changes becomes a `|2-` block scalar. The rendition is regenerated
afterwards with `:spec-render`, which the report names.

**The patterns** are fixed rules of the tool, with no project file:

| Kind | Pattern | Becomes |
|------|---------|---------|
| `provenance` (P1) | a paragraph whose whole text is `_Extrapolated — see <target>._`, `<target>` a path or a round reference | `(<~ <target>)` |
| `trace` (T1) | a parenthesised run of ids, `(FR-12)`, `(FR-07, BQ-405)`, every id of a family in the list below, standing after text in its value | `(-> FR-07, BQ-405)`; runs separated by single spaces become one: `(FR-54) (C16.3)` → `(-> FR-54, C16.3)` |
| `editorial` (E1) | a paragraph of the document root's own content that opens with `**The provenance notes.**` | the paragraph in a `::: {.editorial}` div |
| `references` (R1) | ``(`<doc>.md`, `A > … > B`)`` | `[B](<doc>.tomspecs.md#B)` |
| `references` (R1) | a code span `` `A > … > B` `` whose ids are sections of the document | `[B](#B)` |

An id is a family prefix, an optional `-`, a number, optional `.number` parts and
an optional letter. The families are `FR`, `C`, `BQ`, `RC`, `D`, `N`, `SR`, `UC`,
`TR`, `TD`, `DQ`, `G`, `CL`, `OR`, `X`, `S`, `PR`, `AC`.

**What it never marks**, and how the report names it:

- a run that is the whole value of a form field or a list item (skip
  `wholeValue`) or a whole table cell (skip `wholeCell`), or that has no text
  before it (skip `noTextBefore`): there the ids are the content;
- a run with an id of another family: `(SHA-256)`, `(RS256, ES256)` (skip
  `unknownFamily`; the families are listed with their counts, so the list can be
  extended where one is missing);
- a run directly after `see`, `per`, `under` or `cf.` (candidate
  `afterPreposition`): there the citation is the sentence's object;
- a worded run, `(Project Idea 1.1, C1.2)`, `(DQ-115 (b))` (candidate `worded`),
  and a run holding a code span (candidate `codeSpanInRun`);
- a provenance note followed by more text in its paragraph (candidate
  `moreText`) or quoted in a code span (skip `inCodeSpan`);
- another bold-led paragraph of the root's content (candidate `boldLed`);
- a section path naming an id the document does not have (candidate
  `noSuchSection`);
- anything in a headline, a code span or fenced code (skip `inCode`), a question
  or comment block, or text already inside a div, a span or a citation (skip
  `alreadyMarked`; a reference there is skip `protected`), so a second run
  marks nothing new.

`--kinds` applies only the patterns named (default all four); `--under` limits
the run to the values under a section-id path (the ids of the YAML keys, each
nested in the one before). `--reflow` joins the soft-wrapped lines of
one-paragraph values (no blank line, list, table, quote, fence or hard break
inside); given alone it only reflows, given with `--kinds` it does both.

**The report** gives per kind the number marked, the candidates and the skips by
reason; each change with its section-id path, its YAML line and a before/after
excerpt (ten per kind; `--all` lists every one); every candidate; the id families
not in the list; and every reflowed value.

**Before anything is written**, every changed value is verified: undoing the
run's edits gives back the stored value byte for byte, each edit is the one its
pattern makes, a reflow changed only line breaks, and the value has no notation
finding it did not have. The rewritten YAML must decode to the document with
exactly the changed values changed. Any failure is named (`VERIFY`) and nothing is
written. With `--write` the file goes through a staged sibling
`<doc>.mark-secondary.stage`, read back and renamed over the document.

Exit codes: `0` nothing to mark, or written; `1` changes proposed (a dry run), or
the verification failed; `2` usage.

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
