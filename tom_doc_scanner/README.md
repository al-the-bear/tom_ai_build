# tom_doc_scanner — markdown into section trees

> **Cross-references.**
> [`tom_specs_model/doc/som_multiplatform_spec_model.md`](../tom_specs_model/doc/som_multiplatform_spec_model.md)
> owns the **markdown format** TomSpecs specifications are written in — the
> headline-comment section ids, the uncapped heading depth and the parse
> contract (SOM §11), and the schemas those documents are validated against
> (SOM §13). The
> [DocSpecs specification](../../../_ai/quests/doc_specs/doc_specs_specification.md)
> owns the **DocSpecs format itself**. This README is the catalogue of *what
> this parser produces and how to drive it*; those documents own *what a
> conforming document looks like* and *why*.

Parses markdown files into structured document trees with sections.

## Where this fits

`tom_doc_scanner` turns a markdown file into a traversable tree of sections,
each with a stable id, its source line, its raw headline, its key/value
headline fields and its body text. It exists because no general-purpose
CommonMark parser produces that shape: renderers give you HTML, AST libraries
give you inline nodes, and both stop at `######` — whereas a machine-processed
document needs *identity* (`<!--[install]-->`), *provenance* (which file,
which line, which project) and *unbounded nesting*, because a document's
section depth is a property of the document, not of the six levels HTML
happens to have.

Inside **TomSpecs** — the method that builds software from structured
specification documents — it is the bottom layer of the document tier. The
layer directly above is [`tom_doc_specs`](../tom_doc_specs), which adds schemas,
typed sections and validation to the trees this package produces; above that,
[`tom_specs_clitool`](../tom_specs_clitool) generates the DocSpecs schemas that
TomSpecs specifications are validated against, from the Specification Object
Model in [`tom_specs_model`](../tom_specs_model). The eight non-Dart SOM
runtimes embed their own parse/validate surface rather than a port of this one
(SOM §14), so this package is the **Dart plane's** reader, not a shared
kernel — which is also why it is useful entirely outside TomSpecs, and is used
that way by `tom_markdown_merge` and the Forge markdown editor.

## Overview

A scan is a pure function from text to a tree. `DocScanner` reads a file,
`MarkdownParser` finds every headline in it, and the headlines are folded into
a nested `Section` tree by their `#` level: a heading becomes the child of the
nearest preceding heading of a lower level, and the text between one heading
and the next becomes that section's `text`.

Three things are extracted from a headline beyond its title:

- **The id.** Either declared — `[install]` or `<!--[install]-->` — or derived.
  A single-word headline lowercases to its own id (`Usage` → `usage`); a
  multi-word one takes `parent.index` (`intro.0`), which is stable under
  editing of the *text* but not under reordering, so any id a consumer intends
  to keep should be declared.
- **Key/value fields.** `status="shipped", owner="ada"` inside the headline
  comment is parsed into a `Map<String, String>` and removed from the title.
- **The raw headline**, kept verbatim, so a tool that rewrites a document can
  reproduce the line it came from rather than reconstructing it.

A `Document` is a `Section` with file provenance attached — the absolute path,
the workspace-relative path, the owning project and its root, and the maximum
heading depth found. A `DocumentFolder` is a directory of them, nested to
mirror the directory tree, with `allDocuments` flattening it.

Every entry point comes in an async and a `Sync` form, and every one accepts a
`DocScannerFactory` so a caller can substitute its own `Section` / `Document`
subclasses — which is exactly how `tom_doc_specs` layers `SpecSection` and
`SpecDoc` on top without this package knowing about schemas.

## Installation

```yaml
dependencies:
  tom_doc_scanner: ^0.1.0
```

```bash
dart pub add tom_doc_scanner
```

For the command-line tool:

```bash
dart pub global activate tom_doc_scanner
```

## Features

### Parsing

| Feature | Behaviour |
| ------- | --------- |
| Headline levels | `#` through any number of `#` — **no upper bound**. Levels beyond 6 are parsed as sections; CommonMark renderers show `#######` as literal text, but for a machine format the tree is authoritative (SOM §11.2) |
| Explicit ids | `## [install] Installation` or `## <!--[install]--> Installation` — the comment form keeps the id out of the rendered preview |
| Derived ids | Single word → lowercased; otherwise `parent.index` |
| Headline fields | `key="value"` pairs parsed out of the headline into `Section.fields` |
| Raw headline | The source line kept verbatim in `Section.rawHeadline` |
| Section text | Everything between one headline and the next, in `Section.text` |

### Provenance

| Feature | Behaviour |
| ------- | --------- |
| Line numbers | 1-based source line of every headline |
| Workspace paths | Path relative to a `workspaceRoot` you supply (default: the current directory) |
| Project detection | Owning project — the first path segment below the `workspaceRoot` — with the project-relative path and the project root |
| Hierarchy depth | The deepest heading level in the document |

### Entry points

| Feature | Behaviour |
| ------- | --------- |
| One file | `DocScanner.scanDocument` / `scanDocumentSync` |
| Several files | `DocScanner.scanDocuments` / `scanDocumentsSync` |
| A directory tree | `DocScanner.scanTree` / `scanTreeSync`, recursing into subfolders |
| Custom node types | A `DocScannerFactory` substitutes your own `Section` / `Document` subclasses |
| JSON | `toJson` / `fromJson` on every model, and a `doc_scanner` CLI that writes the files |

## Quick start

```dart
import 'dart:io';
import 'package:tom_doc_scanner/tom_doc_scanner.dart';

Future<void> main() async {
  File('guide.md').writeAsStringSync('''
# Guide

How to use the thing.

## <!--[install]--> Installation

Run the installer.

### Troubleshooting

Check the log.

## Usage

Call it.
''');

  final doc = await DocScanner.scanDocument(filepath: 'guide.md');

  print('${doc.name}  (depth ${doc.hierarchyDepth})');
  for (final s in doc.sections!) {
    print('  ${s.id.padRight(10)} ${s.name}  [${s.sections?.length ?? 0} sub]');
  }
}

// Guide  (depth 3)
//   install    Installation  [1 sub]
//   usage      Usage  [0 sub]
```

Two things to read off that output. `install` is the id the document *declared*
in its headline comment; `usage` was *derived*, because "Usage" is a single
word. And `Troubleshooting` does not appear at the top level — it is the one
sub-section of `Installation`, because `###` nests under the `##` above it.

## Usage

### Scanning a directory tree

```dart
final folder = DocScanner.scanTreeSync(path: 'demo');
print('documents: ${folder.allDocuments.length}');
// documents: 2
```

`scanTree` mirrors the directory structure: `folder.folders` holds the
subdirectories as further `DocumentFolder`s and `folder.documents` the markdown
files at this level. `allDocuments` flattens the whole tree when the structure
does not matter.

### Reading a section

```dart
// demo/a.md:
//   # Release Notes
//
//   ## <!--[r12] status="shipped", owner="ada"--> Release 1.2
//
//   Shipped on Tuesday.

final s = DocScanner.scanDocumentSync(filepath: 'demo/a.md').sections!.first;

print('id=${s.id} name=${s.name}');   // id=r12 name=Release 1.2
print('fields=${s.fields}');          // fields={status: shipped, owner: ada}
print('line=${s.lineNumber}');        // line=3
print('text=${s.text.trim()}');       // text=Shipped on Tuesday.
```

The key/value pairs are parsed out of the headline and are *not* part of
`name` — the title is left clean. `rawHeadline` still holds the original line
in full, for a tool that has to write the document back.

### Custom node types

```dart
class TaggedSection extends Section {
  TaggedSection({
    required super.index, required super.lineNumber,
    required super.rawHeadline, required super.name,
    required super.id, required super.text,
    required super.fields, super.sections,
  });

  bool get isDraft => fields['status'] == 'draft';
}

class TaggedFactory extends DocScannerFactory {
  const TaggedFactory();

  @override
  Section createSection({
    required int index, required int lineNumber,
    required String rawHeadline, required String name,
    required String id, required String text,
    required Map<String, String> fields, List<Section>? sections,
  }) => TaggedSection(
        index: index, lineNumber: lineNumber,
        rawHeadline: rawHeadline, name: name,
        id: id, text: text,
        fields: fields, sections: sections,
      );
}

final doc = DocScanner.scanDocumentSync(
  filepath: 'demo/a.md',
  factory: const TaggedFactory(),
);
final s = doc.sections!.first as TaggedSection;

print('${s.id}  draft=${s.isDraft}');   // r12  draft=false
```

Override `createSection` to change what the tree is made of, `createDocument` to
change the root node; the scanner calls them for every node it builds, so a
whole scan comes back in your own types.

This is the extension point [`tom_doc_specs`](../tom_doc_specs) uses: it passes
a factory that builds `SpecSection` / `SpecDoc`, so the schema layer gets typed
nodes out of an unmodified scan.

### Command line

```bash
# One file → guide.json in the current directory
dart run tom_doc_scanner:doc_scanner scandocument guide.md

# Several files into an output folder
dart run tom_doc_scanner:doc_scanner scandocuments a.md b.md -target=output

# A whole tree, mirroring the directory structure
dart run tom_doc_scanner:doc_scanner scantree docs/ -target=json-output

# The same tree, all output files in one flat folder
dart run tom_doc_scanner:doc_scanner scantree docs/ -flat -target=all-json
```

`-overwrite` replaces existing output instead of renaming around it; `-help`
prints the full option list. Each markdown file becomes a JSON file with the
same base name, holding the section tree and the document's path information.

## Architecture

```
  markdown text
        │
        ▼
  MarkdownParser ......... finds headlines, extracts ids and key/value fields
        │  (ParsedHeadline, startLine, endLine)
        ▼
  DocScanner ............. folds headlines into a tree by level,
        │                  attaches text, resolves file provenance
        │  creates nodes through
        ▼
  DocScannerFactory ...... substitution point for custom node types
        │
        ▼
  Document  ─┬─ Section (nested)
             └─ path / project / depth information

  DocumentFolder ......... a directory of Documents, nested
```

| Type | Responsibility |
| ---- | -------------- |
| `DocScanner` | The entry points — `scanDocument`, `scanDocuments`, `scanTree`, each with a `Sync` twin. Holds the tree-building and provenance logic |
| `MarkdownParser` | Headline recognition, id extraction (both syntaxes), key/value field parsing, id generation and depth calculation. Pure and static |
| `ParsedHeadline` | One recognised headline before it becomes a node: level, name, id, raw text, fields |
| `Section` | A headline and its content — `index`, `lineNumber`, `rawHeadline`, `name`, `id`, `text`, `fields`, and nested `sections` |
| `Document` | A `Section` with file provenance: paths, owning project, load timestamp, `hierarchyDepth` |
| `DocumentFolder` | A directory of documents and subfolders, with `allDocuments` flattening the tree |
| `DocScannerFactory` | Creates `Section` and `Document` instances; subclass it to have the scanner build your own types |

## Ecosystem

```
              tom_doc_scanner        ← this package (depends only on `path`)
                     ▲
      ┌──────────────┴───────────────┬─────────────────────┐
      │  section trees               │                     │
 tom_doc_specs               tom_markdown_merge      tom_md_editor
 schemas, typed sections,    document merging        the Forge markdown
 validation                                          editor
      ▲
      │  DocSpecs documents + schemas
 tom_specs_clitool ......... generates *.docspecs-schema.yaml from the SOM
      ▲
      │
 tom_specs_model ........... the Specification Object Model
```

The upward chain is TomSpecs; the two branches on the right are not. Nothing in
this package knows about schemas, TomSpecs or the SOM — that is what lets those
three consumers sit side by side.

## Further documentation

**TomSpecs subject matter** — the authorities this package's readers need:

| Document | Authority for |
|----------|---------------|
| [index.md](../tom_specs_model/doc/index.md) | The catalogue of the whole TomSpecs document set, and the `§` citation convention used throughout it |
| [som_multiplatform_spec_model.md](../tom_specs_model/doc/som_multiplatform_spec_model.md) | The markdown format TomSpecs documents use — section ids, uncapped depth, the parse contract (SOM §11) — the schemas they are validated against (SOM §13), and why the non-Dart runtimes embed their own reader instead of porting this one (SOM §14) |
| [doc_specs_specification.md](../../../_ai/quests/doc_specs/doc_specs_specification.md) | The DocSpecs format itself: schemas, section types, validation rules |
| [tom_specs_project_flow.md](../tom_specs_model/doc/tom_specs_project_flow.md) | The TomSpecs creation process — the phases whose documents this parser reads |

**Siblings** — packages you will reach for next:

| Package | What it is |
|---------|-----------|
| [tom_doc_specs](../tom_doc_specs) | Schemas, typed sections and validation on top of these trees |
| [tom_specs_clitool](../tom_specs_clitool) | Generates the DocSpecs schemas TomSpecs documents are validated against |
| [tom_specs_model](../tom_specs_model) | The Specification Object Model those schemas are generated from |

## Status

Version **0.1.0**, published on pub.dev. **74 tests**, all passing.
