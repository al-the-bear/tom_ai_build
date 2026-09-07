# tom_doc_specs — schema validation for markdown

> **Cross-references.**
> The [DocSpecs specification](../../../_ai/quests/doc_specs/doc_specs_specification.md)
> owns the **DocSpecs format itself** — what a schema may declare, what a
> section type is, and what makes a document conforming.
> [`tom_specs_model/doc/som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
> owns the **TomSpecs specification format** written on top of it (SOM §11) and
> the schemas TomSpecs generates to validate it (SOM §13). This README is the
> catalogue of *what this package checks and how to drive it*; those documents
> own *what the rules are* and *why*.

Document schema validation for structured markdown, extending DocScanner with
typed sections.

## Where this fits

`tom_doc_specs` decides whether a markdown document keeps the promises its
schema makes. A document names a schema in its first headline
(`<!-- schema=release-notes/1.0 -->`); the package resolves that schema from a
`.tom/docspecs-schema/` folder, re-reads the document as a tree of **typed**
sections, and reports every required section that is missing, every section
whose id does not match its declared type, and every ordering rule that is
broken. It exists because markdown has structure a reader can see and a program
cannot: "the Requirements section comes after Overview and every requirement
has an id" is a real constraint with no place to live in the file — so it lives
in a schema beside it, and this package is what enforces it.

Inside **TomSpecs** — the method that builds software from structured
specification documents — that enforcement is the document tier's contract.
TomSpecs specifications *are* DocSpecs documents (SOM §11), and the schemas they
are validated against are generated from the Specification Object Model by
[`tom_specs_clitool`](../tom_specs_clitool) (SOM §13), with their exact spelling
fixed against this parser. The eight non-Dart SOM runtimes embed their own
validation surface rather than a port of this one (SOM §14), so this package is
the **Dart plane's** validator, not a shared kernel — which is also why it is
useful entirely outside TomSpecs, for any markdown you want to hold to a shape.

## Overview

The layer below is [`tom_doc_scanner`](../tom_doc_scanner), which turns markdown
into a plain `Document` / `Section` tree. This package adds three things on top:

- **A schema.** A `*.docspecs-schema.yaml` file declares `section-types` (each
  with an id `prefix`) and a `document` structure naming which sections must
  appear, in what order, and which are optional. Schemas are resolved by id from
  `.tom/docspecs-schema/` folders, walking up from the document to the workspace
  root and then to `~/.tom/docspecs-schema/`.
- **Typed nodes.** A `DocSpecsFactory` is handed to the scanner, so the scan
  comes back as `SpecDoc` / `SpecSection` — each section's `type` resolved by
  matching its id against the schema's prefixes, with its `tags`, `format` and
  `formFields` parsed out.
- **Validation.** `DocSpecsValidator` walks the typed tree against the schema
  and returns `ValidationError`s that name the section and say what to do about
  it. `SpecDoc.isValid` is the one-line answer — read together with
  `SpecDoc.wasValidated`, which says whether a schema was found at all. A
  document nothing checked has no errors either, and those two states must not
  read the same.

Two things fall out of having the schema in hand. `DocSpecsSkeletonGenerator`
turns a schema into an empty conforming document, so a new document starts in
the right shape rather than being corrected into it; and `AiValidator` is a hook
for the constraints that are about *meaning* rather than *structure* — the
package expands the schema's own prose rules into prompts and hands them to your
implementation, which is the only part that talks to a language model.

Every entry point comes in an async and a `Sync` form.

## Installation

```yaml
dependencies:
  tom_doc_specs: ^0.1.0
```

```bash
dart pub add tom_doc_specs
```

For the command-line tool:

```bash
dart pub global activate tom_doc_specs
```

## Features

### Schemas

| Feature | Behaviour |
| ------- | --------- |
| Schema declaration | `<!-- schema=id/version -->` in the document's first headline |
| Section types | Named types, each claiming sections by an id `prefix`, matched in YAML declaration order |
| Document structure | Which sections are required, their order, which are `optional: true` |
| Access keys | `access-key: overview` gives a section a stable lookup name independent of its id |
| Resolution | By id from `.tom/docspecs-schema/`, walking up from the document, then `~/.tom/docspecs-schema/` |
| Versions | `id-1.0.docspecs-schema.yaml`; the highest matching version wins when resolving by type |
| Expansion | `[[key]]` references inside a schema are expanded by `SchemaExpander` before use |

### Typed access

| Feature | Behaviour |
| ------- | --------- |
| `SpecDoc` | A `Document` with `schemaId`, `validationErrors`, `isValid` and `wasValidated` |
| `SpecSection` | A `Section` with its resolved `type`, `tags`, `format`, `formFields` and `preamble` |
| By id or access key | `doc['note-001']` and `doc['overview']` both reach the same section |
| By type | `doc.getSpecSectionType('requirement').getAll()` — every section of a type, anywhere in the document |
| By tag | `doc.getSectionsByTag('priority')`, optionally narrowed to one type |
| JSON | `toJson` / `fromJson` on `SpecDoc`, so a validated document survives a process boundary |

### Validation and generation

| Feature | Behaviour |
| ------- | --------- |
| Structural validation | Missing required sections, unknown sections, wrong order, id/type mismatches, missing form fields |
| Error detail | `ValidationError` carries a category, the offending section and a remedy line |
| Checked vs clean | `wasValidated` is `false` when no schema could be resolved, so an unchecked document cannot pass for a valid one |
| AI validation | `validateAsync` runs the schema's prose rules through an `AiValidator` you implement; the sync `validate` never calls it |
| Prompt expansion | `PromptExpander` fills `${...}` placeholders in a schema's prompts from the document, before the prompt is handed over |
| Skeletons | `DocSpecsSkeletonGenerator.generate(schema)` emits an empty conforming document |
| Insert markers | `<!--$insert:name-->` … `<!--$end-insert-->` regions a tool may rewrite without touching the rest |

## Quick start

Given a schema at `.tom/docspecs-schema/release-notes-1.0.docspecs-schema.yaml`:

```yaml
section-types:
  note:
    prefix: note
  requirement:
    prefix: req

document:
  sections:
    note-001:
      section-type: note
      access-key: overview
    requirements:
      section-type: requirement
```

and a document `notes.md` beside it:

```markdown
# Release Notes <!-- schema=release-notes/1.0 -->

## <!--[note-001]--> Overview

What shipped in 1.2.

## <!--[req-001]--> Requirements

The system shall log every release.

## <!--[req-002]--> More Requirements

The log shall be append-only.
```

```dart
import 'package:tom_doc_specs/tom_doc_specs.dart';

Future<void> main() async {
  final doc = await DocSpecs.scanDocument(filePath: 'notes.md');

  print('schema=${doc.schemaId}  valid=${doc.isValid}');
  for (final s in doc.getSpecSectionType('requirement').getAll()) {
    print('  ${s.id}  ${s.name}');
  }
}

// schema=release-notes/1.0  valid=true
//   req-001  Requirements
//   req-002  More Requirements
```

Both requirement sections were found by *type*, not by position — the schema
says sections whose id starts with `req` are of type `requirement`, so a third
one added tomorrow is picked up without changing this code.

## Usage

### Declaring a schema

A document says which schema it follows in its **preamble** — everything above
the second heading. Two forms are read, and both are equally good:

```markdown
<!-- docspec: release-notes/1.0 -->
# Release Notes
```

```markdown
# Release Notes <!-- schema=release-notes/1.0 -->
```

The standalone comment may sit above or below the title; whichever form appears
first wins. Bounding the search at the second heading is what stops a
`<!-- docspec: … -->` quoted inside some section's body from being taken for the
document's own declaration.

Passing `schemaId:` to `scanDocument` overrides whatever the document says.

**When neither the document nor the caller names a schema, nothing is
validated** — and that is not a pass:

```dart
final doc = await DocSpecs.scanDocument(filePath: 'plain.md');

print(doc.wasValidated);   // false — no schema was found
print(doc.isValid);        // true, and it means nothing: nothing was checked
```

`isValid` only reports that no error was *recorded*. Check `wasValidated &&
isValid` when you mean "this document is known to be correct". The `docspecs`
CLI makes the same distinction: an undeclared document is reported `?`, never
`✓`.

### Reporting what is wrong

Delete the two requirement sections from that document and the same scan says
so:

```dart
final doc = await DocSpecs.scanDocument(filePath: 'broken.md');

print('valid=${doc.isValid}');
for (final e in doc.validationErrors) {
  print('  $e');
}

// valid=false
//   Required section 'requirements' (type 'requirement') is missing. Add a
//   section whose ID starts with 'req' (e.g. 'req-001' or 'req-requirements').
```

The remedy is part of the message by design: a validator that only says
*"missing"* leaves the reader to open the schema and work out what would satisfy
it.

### Reaching a section

```dart
print(doc['note-001']?.name);   // Overview
print(doc['overview']?.name);   // Overview
```

`doc[...]` matches the section id first, then the schema's access keys. Ids
change when a document is reorganised; an access key is what a *program* should
depend on, so the code that reads "the overview" keeps working.

### Generating a skeleton

```dart
final schema = DocSpecs.loadSchemaSync(
  schemaId: 'release-notes/1.0',
  documentPath: 'notes.md',
)!;
print(DocSpecsSkeletonGenerator.generate(schema));

// <!-- docspec: release-notes/1.0 -->
//
// # [note-note-001] Note 001
//
//
// ## [req-requirements] Requirements
```

A skeleton is a starting point, not a valid document — it carries placeholder
content and its sections are the ones the schema *requires*, so validating one
straight out of the generator will report what you have not filled in yet. That
is the point of it.

Two rough edges are visible in that output and are tracked as
`tsdocc1_aigi`: headings are named and identified from the schema's **section
key** rather than its `access-key`, so a key of `note-001` becomes
`[note-note-001] Note 001`; and the first document section is emitted at level 1,
where the scanner reads it as the document *title* rather than as a section.

It does now **scan back with its own schema**, though: `DocSpecs.scanDocument`
reads both declaration forms out of a document's preamble — the standalone
`<!-- docspec: id/version -->` comment the generator writes, and the older
`schema=id/version` inside the first headline.

### Command line

```bash
# Validate — prints ✓ / ✗ per file and a summary
docspecs validate notes.md

# Validate a whole tree of *.docspec.md files
docspecs validate ./docs --recursive

# Force a schema instead of reading it from the document
docspecs validate notes.md -schema=release-notes/1.0

# Scan into JSON (or YAML) for another tool to consume
docspecs scan notes.md -target=./output
docspecs scan notes.md -format=yaml

# List the schemas installed in ~/.tom/docspecs-schema/
docspecs list-schemas
```

`-quiet` suppresses the per-file lines, `-overwrite` replaces existing scan
output, `--no-ai` skips the language-model pass, and `-help` prints the full
option list. The exit code is the machine-readable answer:

| Code | Meaning |
| ---- | ------- |
| `0` | Every document validated |
| `1` | At least one document is invalid (or the command was unknown) |
| `2` | The named schema could not be resolved |
| `3` | A named file does not exist |

## Architecture

```
  markdown + <!-- schema=id/version -->
        │
        ▼
  DocSpecs ............... the entry points; extracts the schema id,
        │                  resolves the schema, scans, then validates
        ├──────────────► SchemaResolver / SchemaLoader
        │                  finds *.docspecs-schema.yaml by id and version
        │                  SchemaExpander resolves [[key]] references
        │
        ├──────────────► DocScanner (tom_doc_scanner)
        │                  driven with a DocSpecsFactory, so the tree
        │                  comes back as SpecDoc / SpecSection
        │
        └──────────────► DocSpecsValidator ──► List<ValidationError>
                           structure, order, ids, tags, form fields
```

| Type | Responsibility |
| ---- | -------------- |
| `DocSpecs` | The façade — `scanDocument`, `scanDocuments`, `scanTree`, `loadSchema`, `validate`, `listSchemas`, each with a `Sync` twin |
| `DocSpecSchema` | A parsed schema: `id`, `version`, its `SectionTypeDef`s, its `DocumentStructure`, and the optional `FormTypeDef`s, subsection declarations and custom tags |
| `SchemaLoader` | Reads one `*.docspecs-schema.yaml` into a `DocSpecSchema` |
| `SchemaResolver` | Finds the schema for an id or a document, walking `.tom/docspecs-schema/` folders outward |
| `SchemaDiscovery` | Enumerates the schemas visible from a location, as `SchemaInfo` |
| `SchemaExpander` | Expands `[[key]]` references within a schema before it is used |
| `DocSpecsFactory` | The `DocScannerFactory` that makes the scanner build `SpecDoc` / `SpecSection` and resolves each section's type by prefix |
| `SpecDoc` | A validated document — `schemaId`, `validationErrors`, `isValid`, `wasValidated`, `getSection`, `getSpecSectionType`, `getSectionsByTag` |
| `SpecSection` | A typed section — `type`, `tags`, `format`, `formFields`, `preamble`, `getSubsectionsByType` |
| `SpecSectionType` | Every section of one type, grouped by the section it was found under |
| `DocSpecsValidator` | The structural check, returning `ValidationError`s |
| `AiValidator` | The interface you implement to have `validateAsync` also check the schema's prose rules |
| `PromptExpander` | Fills `${...}` placeholders in a schema's prompts from the document |
| `DocSpecsSkeletonGenerator` | Turns a schema into an empty conforming document |
| `InsertMarker` / `InsertMarkerParser` / `InsertMarkerProcessor` | Finds and rewrites `<!--$insert:name-->` regions |
| `ValidationError` | One finding: its `ValidationErrorCategory`, where it is, and what to do |

## Ecosystem

```
              tom_doc_scanner ......... markdown → section trees
                     ▲
                     │  scans with a DocSpecsFactory
              tom_doc_specs           ← this package
                     ▲
                     │  DocSpecs documents + schemas
         tom_specs_clitool ........... generates *.docspecs-schema.yaml
                     ▲                 from the SOM
                     │
           tom_specs_model ........... the Specification Object Model
```

`tom_doc_scanner` knows nothing about schemas; this package knows nothing about
TomSpecs or the SOM. The TomSpecs connection is made one layer up, where
`tom_specs_clitool` generates schemas this package then enforces — which is what
lets the package be used on any structured markdown at all.

## Further documentation

**TomSpecs subject matter** — the authorities this package's readers need:

| Document | Authority for |
|----------|---------------|
| [doc_specs_specification.md](../../../_ai/quests/doc_specs/doc_specs_specification.md) | The DocSpecs format itself: schemas, section types, validation rules |
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of the whole TomSpecs document set, and the `§` citation convention used throughout it |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | The TomSpecs markdown format (SOM §11), the schemas generated to validate it (SOM §13), and why the non-Dart runtimes embed their own validator instead of porting this one (SOM §14) |
| [tom_specs_project_flow.md](../tom_specs_model/doc/tom_specs_project_flow.md) | The TomSpecs creation process — the phases whose documents these schemas hold |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_doc_scanner](../tom_doc_scanner) | The markdown parser underneath: section trees, ids, provenance |
| [tom_specs_clitool](../tom_specs_clitool) | Generates the DocSpecs schemas TomSpecs documents are validated against |
| [tom_specs_model](../tom_specs_model) | The Specification Object Model those schemas are generated from |

## Status

Version **0.2.0** — **0.1.0** is the release on pub.dev; 0.2.0 is unpublished. **253 tests**, all passing.
