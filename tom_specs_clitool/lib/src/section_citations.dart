/// Resolves the `§`-citations in the TomSpecs documents, so `index.md`'s
/// citation convention can be decided by a program rather than by a reader.
///
/// ## Why this exists
///
/// The convention used to say that a bare `§N` — a section sign with no document
/// in front of it — is unresolvable and always a defect. Taken literally that
/// condemned some sixteen hundred sites: intra-document self-reference is
/// pervasive and idiomatic across the doc set, and one document had already
/// declared a private carve-out for itself. The convention as written was not the
/// convention as practised, and while that gap stood no mechanical check was
/// possible — a checker could not tell a legitimate self-citation from a citation
/// that had lost its document.
///
/// `index.md` now carves the self-reference out explicitly: a bare `§N` means
/// *this document*. That single change makes the rule decidable, and this library
/// is the decision procedure:
///
/// 1. A citation is **qualified** when a document name governs it, otherwise it
///    is **bare**.
/// 2. A bare citation resolves against the headings of the file it is written in.
/// 3. A qualified citation resolves against the headings of the file it names.
/// 4. A citation that resolves to no heading is a defect — and now a *findable*
///    one.
///
/// ## The five ways a document name governs a citation
///
/// All five are in use across the corpus. They are here because the documents
/// read correctly with them and would read absurdly without them — not to widen
/// the check's tolerance.
///
/// - **Immediately before.** `` `codespecs_mapping.md` §9.2 ``, `SOM §11.4`, or
///   the tail of a markdown link, `[x.md](x.md) §10`. The lookback crosses a soft
///   line wrap, because a citation and its document name are routinely split by
///   one.
/// - **`§N of <file>.md`.** The name follows instead of leading. Unambiguous, and
///   the natural English where the section is the sentence's subject.
/// - **The run.** Documents write `§4.1 / §4.2 / §4.3` and `(§5.2, §5.8)`;
///   requiring each member to repeat the name would be noise. A qualifier governs
///   the run it opens: a following citation inherits it when nothing but a run
///   joiner separates the two (see [_runJoiner]). Anything else — a word, an em
///   dash, a table-cell bar — ends the run.
/// - **The table row.** In a document-map table, the first cell *is* the
///   document, and every `§N` in the row is one of its sections. The clause is
///   narrow on purpose: it applies only when that cell holds a document reference
///   **and nothing else**. A first cell that merely mentions a document — SOM's
///   own serialization tables cite `tom_specs_model_rules.md §5.2` in column one
///   and their own sections in column two — is not a document map, and the row
///   scope must not fire on it.
/// - **The table column.** The transpose of the row rule: a table that indexes a
///   companion document section by section heads that column with the document,
///   `` | Area | Role | `llm_and_d4rt_tools.md` § | ``, and every cell beneath it
///   carries only the number. Same "and nothing else" guard, with one addition —
///   the header cell may carry a bare `§`, and it is that sign which makes the
///   header *say* the column holds sections rather than merely mention a file.
///   Without this rule such a table has to repeat the document name once per row,
///   which is the shape of defeat the self-reference carve-out already refused.
///
/// The narrowness elsewhere is equally deliberate. A joiner set that swallowed
/// prose would let a document name mentioned two clauses earlier vouch for a
/// citation, which is exactly the silent mis-resolution the rule exists to
/// prevent.
///
/// ## Resolution is exact
///
/// An id resolves when a heading **declares** it — not when an ancestor or a
/// descendant does. Both relaxations were tried against the real doc set and both
/// hide real defects: resolving `§5.23` through an existing `§5` would excuse a
/// hundred citations that belong to another document, and it cannot be
/// distinguished from the genuine case (`§12.3.6` naming rule 6 inside a section
/// with no `12.3.x` headings) by anything a parser can see. So a citation that
/// addresses a numbered item rather than a heading says so in words — "rule 6 of
/// §12.3" — and a citation written as a section number has to be one.
///
/// ## What counts as a citation
///
/// A section id is either a **dotted number** (`5.23`, `10.2`) or an
/// **upper-case symbolic id** (`PF-DOC-PUR` — `tom_specs_project_flow.md` numbers
/// its headings that way). Everything else after a `§` is not a citation:
/// `§oneof`, `§item` and `§content` are DocSpecs section-type names, and the `§N`
/// of the convention's own prose is a metavariable. Keying on the *shape* of the
/// id rather than on a list of exceptions means a new document using either
/// scheme is covered on the day it is written.
///
/// ## What it does *not* do
///
/// It checks that a citation **resolves**, not that it is **apt** — `index.md`'s
/// "cite by subject, not by number" is a rule for humans, and a number that
/// resolves to the wrong heading looks identical to one that resolves to the
/// right heading. The mechanical half is the half that decays silently.
///
/// A qualified citation naming a document outside the corpus is reported as
/// [SectionCitationVerdict.unverifiable] rather than as a defect: the checker
/// cannot see the file, which is not the same as the citation being wrong.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The shape of a section id: a dotted number, or an upper-case symbolic id.
///
/// Both schemes are in use — `codespecs_mapping.md` numbers its headings `4.1.2`,
/// `tom_specs_project_flow.md` names its own `PF-FLW-OVE`.
const String sectionIdPattern = r'(?:\d+(?:\.\d+)*|[A-Z]{2,}(?:-[A-Z0-9]+)+)';

/// A `§` followed by an optional space and a section id.
final RegExp _citation = RegExp('§[  ]?($sectionIdPattern)');

/// A numbered or symbolically-identified heading, `## 4.1 Title` /
/// `### PF-DOC-PUR Purpose`. The dot after a number is optional because both
/// `## 4.` and `## 4` occur.
final RegExp _heading =
    RegExp('^(#{1,6})[ \t]+($sectionIdPattern)\\.?(?:[ \t]+(.*))?\$');

/// Fenced code blocks, whose contents are not prose.
final RegExp _fence = RegExp(r'^\s{0,3}(```|~~~)');

/// A markdown table row.
final RegExp _tableRow = RegExp(r'^\s{0,3}\|');

/// A list item, which starts a new thought and so a new lookback block.
final RegExp _listItem = RegExp(r'^\s*(?:[-*+]|\d+[.)])\s');

/// A document name standing immediately before a `§`.
///
/// Accepts the file name bare, in backticks, or as the tail of a markdown link —
/// hence the `)` among the characters skipped — and accepts `SOM`, the short form
/// the convention reserves for `som_multiplatform_spec_model.md` because those
/// citations appear inside fixed-width comment banners in generated source.
final RegExp _leadingQualifier =
    RegExp(r'(?:([A-Za-z0-9_.-]+\.md)|\bSOM)[`*_)\]\s ]*$');

/// A document name standing just after a citation — `§11 of `x.md``.
final RegExp _trailingQualifier =
    RegExp(r'^[\s ]+(?:of|in)[\s ]+[`*_(\[]*([A-Za-z0-9_.-]+\.md)');

/// A table cell holding a document reference **and nothing else**.
final RegExp _documentOnlyCell = RegExp(
    r'^[\s`*_]*(?:\[[^\]]*\]\(\s*)?([A-Za-z0-9_.-]+\.md)(?:\s*\))?[\s`*_]*$');

/// A table **header** cell holding a document reference and nothing else but an
/// optional bare `§` — `` `llm_and_d4rt_tools.md` § ``.
///
/// The trailing sign is what makes the header say "this column holds sections of
/// that document" rather than merely mentioning it, so it is admitted here and
/// nowhere else.
final RegExp _documentColumnHeaderCell = RegExp(
    r'^[\s`*_]*(?:\[[^\]]*\]\(\s*)?([A-Za-z0-9_.-]+\.md)(?:\s*\))?'
    r'[\s`*_]*§?[\s`*_]*$');

/// The `|---|:--:|` row that turns the line above it into a header.
final RegExp _tableDelimiterRow =
    RegExp(r'^\s{0,3}\|(?:\s*:?-{2,}:?\s*\|)+\s*$');

/// The document `SOM` abbreviates.
const String somDocument = 'som_multiplatform_spec_model.md';

/// The files outside the doc folder that cite it, container-root-relative.
///
/// A project README is the one place outside `tom_specs_model/doc` that cites
/// the doc set by section, and it decays the same way — so the gate covers the
/// READMEs too rather than only the folder that happens to hold the headings.
///
/// The list is enumerated rather than discovered: a sweep for "every README in
/// the workspace" would pull in projects that neither cite nor are cited by
/// TomSpecs, and their unrelated `§` usage would have to be exempted one by one.
const defaultCitedReadmes = [
  'tom_ai/ai_build/tom_code_specs/README.md',
  'tom_ai/ai_build/tom_spec_engine/README.md',
  'tom_ai/ai_build/tom_specs_clitool/README.md',
  'tom_ai/ai_build/tom_specs_core/README.md',
  'tom_ai/ai_build/tom_specs_model/README.md',
  'tom_ai/core/tom_core_codespecs/README.md',
];

/// Text that joins two citations of one run rather than separating two thoughts.
///
/// Deliberately short: whitespace and the punctuation that enumerates or ranges.
/// `and`, `to` and `through` are in because the documents write `§4.1 and §4.2`;
/// an em dash is out because it opens a clause, and a `|` is out because it ends
/// a table cell.
bool _runJoiner(String gap) =>
    RegExp(r'^[\s,;/&+~–-]*(?:(?:and|or|to|through|plus)[\s,;/&+~–-]*)?$')
        .hasMatch(gap);

/// One heading that carries a section id.
class SectionHeading {
  /// The id as written, `4.1.2` or `PF-FLW-OVE`.
  final String id;

  /// Number of leading `#`.
  final int level;

  /// The heading text after the id, or `''`.
  final String title;

  /// 1-based line number.
  final int line;

  /// Creates a heading.
  const SectionHeading({
    required this.id,
    required this.level,
    required this.title,
    required this.line,
  });

  @override
  String toString() => '§$id $title';
}

/// The section ids one document declares.
class DocumentSections {
  /// Absolute path of the document.
  final String path;

  /// File name, which is what citations name.
  final String name;

  /// Every id-carrying heading, keyed by id, in file order.
  final Map<String, SectionHeading> byId;

  /// Creates the set.
  const DocumentSections({
    required this.path,
    required this.name,
    required this.byId,
  });

  /// Whether a heading of this document declares [id].
  bool declares(String id) => byId.containsKey(id);

  /// Parses the id-carrying headings of [markdown].
  static DocumentSections parse(String markdown, {required String path}) {
    final byId = <String, SectionHeading>{};
    var inFence = false;
    final lines = markdown.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_fence.hasMatch(line)) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;
      final match = _heading.firstMatch(line);
      if (match == null) continue;
      // First declaration wins: a duplicate id is a defect of its own, and
      // resolution only needs to know that the id exists.
      byId.putIfAbsent(
        match.group(2)!,
        () => SectionHeading(
          id: match.group(2)!,
          level: match.group(1)!.length,
          title: (match.group(3) ?? '').trim(),
          line: i + 1,
        ),
      );
    }
    return DocumentSections(path: path, name: p.basename(path), byId: byId);
  }

  /// Reads and parses [path].
  static DocumentSections read(String path) =>
      parse(File(path).readAsStringSync(), path: path);
}

/// Every document a citation may resolve against.
class SectionCorpus {
  final Map<String, DocumentSections> _byName;

  /// Creates a corpus from parsed documents.
  SectionCorpus(Iterable<DocumentSections> documents)
      : _byName = {for (final d in documents) d.name: d};

  /// The documents, in name order.
  List<DocumentSections> get documents =>
      _byName.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  /// The document named [name], or `null` when the corpus does not hold it.
  DocumentSections? operator [](String name) => _byName[name];

  /// Number of documents held.
  int get length => _byName.length;

  /// Reads every `*.md` directly inside [docDir].
  ///
  /// Only the folder itself: the TomSpecs doc set is flat by design, and
  /// generator output lives in a sibling tree that must not be scanned — a
  /// generated file is regenerated, not edited.
  static SectionCorpus loadFolder(String docDir) {
    final dir = Directory(docDir);
    if (!dir.existsSync()) {
      throw ArgumentError.value(
          docDir, 'docDir', 'documentation folder not found');
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path) == '.md')
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return SectionCorpus([for (final f in files) DocumentSections.read(f.path)]);
  }
}

/// How a citation acquired its document name.
enum SectionQualifierSource {
  /// No document name governs it — it means the file it is written in.
  bare,

  /// A document name stands immediately before it, possibly across a soft wrap.
  leading,

  /// The name follows it: `§11 of `llm_and_d4rt_tools.md``.
  trailing,

  /// Inherited from the citation it follows in a run.
  run,

  /// Taken from the first cell of a document-map table row.
  tableRow,

  /// Taken from the header cell of the column the citation sits in.
  tableColumn,
}

/// What the resolver concluded about one citation.
enum SectionCitationVerdict {
  /// Bare, and the id resolves in the document it is written in — the
  /// self-reference `index.md` carves out. Correct as written.
  self,

  /// Qualified, and the id resolves in the document it names. Correct.
  crossDocument,

  /// Bare, and no heading of its own document declares the id. The citation has
  /// lost its document name and points a reader nowhere.
  dangling,

  /// Qualified, but the named document declares no such section — a number that
  /// moved, or one carried across from a third document.
  wrongSection,

  /// Qualified with a document the corpus does not hold, so nothing can be
  /// concluded. Not a defect.
  unverifiable,
}

/// One `§` citation.
class SectionCitation {
  /// The section id as written, without the `§`.
  final String id;

  /// The document the citation resolves against, or `null` when bare.
  final String? document;

  /// How [document] was acquired.
  final SectionQualifierSource source;

  /// True when the qualifier was written as the `SOM` short form.
  final bool viaShortForm;

  /// Path of the file the citation is in.
  final String file;

  /// 1-based line number.
  final int line;

  /// The line's text, for the failure message.
  final String context;

  /// The verdict.
  final SectionCitationVerdict verdict;

  /// Creates a citation.
  const SectionCitation({
    required this.id,
    required this.document,
    required this.source,
    required this.viaShortForm,
    required this.file,
    required this.line,
    required this.context,
    required this.verdict,
  });

  /// True when the citation must fail the check.
  bool get isViolation =>
      verdict == SectionCitationVerdict.dangling ||
      verdict == SectionCitationVerdict.wrongSection;

  /// A one-line, `file:line`-prefixed description suitable for a build log.
  String describe({String? relativeTo}) {
    final where = relativeTo == null ? file : p.relative(file, from: relativeTo);
    return '$where:$line: §$id — ${_reason()}';
  }

  String _reason() => switch (verdict) {
        SectionCitationVerdict.self => 'SELF',
        SectionCitationVerdict.crossDocument =>
          'OK → $document (${source.name})',
        SectionCitationVerdict.dangling =>
          'DANGLING — bare, and ${p.basename(file)} declares no §$id. A bare '
              'citation means this document, so name the one it belongs to: '
              '`<file>.md §$id`',
        SectionCitationVerdict.wrongSection =>
          'NO SUCH SECTION — $document declares no §$id',
        SectionCitationVerdict.unverifiable =>
          'UNVERIFIABLE — $document is outside the scanned corpus',
      };
}

/// A stretch of lines a citation may look back over for its document name.
///
/// A block ends at a blank line, a heading, a fence, a table row or a list
/// marker — each of which starts a new thought, and none of which should let a
/// document name reach forward into the next one.
class _Block {
  _Block(this.text, this.firstLine);

  final String text;
  final int firstLine;

  /// 1-based line number of [offset] within the document.
  int lineAt(int offset) =>
      firstLine + '\n'.allMatches(text.substring(0, offset)).length;
}

List<_Block> _blocksOf(List<String> lines) {
  final blocks = <_Block>[];
  final buffer = <String>[];
  var start = 0;

  void flush() {
    if (buffer.isEmpty) return;
    blocks.add(_Block(buffer.join('\n'), start + 1));
    buffer.clear();
  }

  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_fence.hasMatch(line)) {
      flush();
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final breaks = line.trim().isEmpty ||
        _heading.hasMatch(line) ||
        line.startsWith('#') ||
        _tableRow.hasMatch(line) ||
        _listItem.hasMatch(line);
    if (breaks) flush();
    if (line.trim().isEmpty) continue;
    if (buffer.isEmpty) start = i;
    buffer.add(line);
    // A table row is a block of its own: the next row is a different subject.
    if (_tableRow.hasMatch(line)) flush();
  }
  flush();
  return blocks;
}

/// The document a document-map row is about, or `null` when the row is not one.
String? _rowScope(String line) {
  if (!_tableRow.hasMatch(line)) return null;
  final cells = line.trim().split('|');
  // `| a | b |` splits to ['', ' a ', ' b ', ''] — the first cell is index 1.
  if (cells.length < 3) return null;
  return _documentOnlyCell.firstMatch(cells[1])?.group(1);
}

/// The document each column of a header row is about, keyed by column index.
///
/// Empty when no column names one, which is the ordinary case.
Map<int, String> _columnScopes(String headerRow) {
  final cells = headerRow.trim().split('|');
  final scopes = <int, String>{};
  for (var i = 1; i < cells.length - 1; i++) {
    final document = _documentColumnHeaderCell.firstMatch(cells[i])?.group(1);
    if (document != null) scopes[i] = document;
  }
  return scopes;
}

/// Which cell of [row] the character at [offset] falls in, 1-based to match the
/// indices [_columnScopes] returns.
int _columnAt(String row, int offset) {
  final leading = row.length - row.trimLeft().length;
  var column = 0;
  for (var i = leading; i < offset && i < row.length; i++) {
    if (row[i] == '|') column++;
  }
  return column;
}

/// Finds and resolves every `§` citation in [markdown].
///
/// [path] names the file the citations are in — it decides what a bare citation
/// resolves against — and is not read.
List<SectionCitation> classifySectionCitations(
  String markdown, {
  required String path,
  required SectionCorpus corpus,
  DocumentSections? own,
}) {
  final self =
      own ?? corpus[p.basename(path)] ?? DocumentSections.parse(markdown, path: path);
  final citations = <SectionCitation>[];

  final blocks = _blocksOf(markdown.split('\n'));
  // The column scopes of the table currently being walked. A table row is its
  // own block, so a header is recognised by the delimiter row that follows it,
  // and any non-table block ends the table and clears the scopes.
  var columnScopes = const <int, String>{};

  for (var b = 0; b < blocks.length; b++) {
    final block = blocks[b];
    if (!_tableRow.hasMatch(block.text)) {
      columnScopes = const {};
    } else if (b + 1 < blocks.length &&
        _tableDelimiterRow.hasMatch(blocks[b + 1].text)) {
      columnScopes = _columnScopes(block.text);
    }

    final rowScope = _rowScope(block.text);

    var previousEnd = -1;
    String? previousDocument;

    for (final match in _citation.allMatches(block.text)) {
      final before = block.text.substring(0, match.start);
      final after = block.text.substring(match.end);

      String? document;
      var source = SectionQualifierSource.bare;
      var viaShortForm = false;

      final leading = _leadingQualifier.firstMatch(before);
      final trailing = _trailingQualifier.firstMatch(after);
      if (leading != null) {
        document = leading.group(1) ?? somDocument;
        viaShortForm = leading.group(1) == null;
        source = SectionQualifierSource.leading;
      } else if (trailing != null) {
        document = trailing.group(1);
        source = SectionQualifierSource.trailing;
      } else if (previousEnd >= 0 &&
          previousDocument != null &&
          _runJoiner(block.text.substring(previousEnd, match.start))) {
        document = previousDocument;
        source = SectionQualifierSource.run;
      } else if (rowScope != null) {
        document = rowScope;
        source = SectionQualifierSource.tableRow;
      } else if (columnScopes.isNotEmpty) {
        final scope = columnScopes[_columnAt(block.text, match.start)];
        if (scope != null) {
          document = scope;
          source = SectionQualifierSource.tableColumn;
        }
      }

      citations.add(SectionCitation(
        id: match.group(1)!,
        document: document,
        source: source,
        viaShortForm: viaShortForm,
        file: path,
        line: block.lineAt(match.start),
        context: block.text.split('\n')[
            block.lineAt(match.start) - block.firstLine],
        verdict: _verdictFor(match.group(1)!, document, self, corpus),
      ));

      previousEnd = match.end;
      previousDocument = document;
    }
  }

  return citations;
}

SectionCitationVerdict _verdictFor(
  String id,
  String? document,
  DocumentSections self,
  SectionCorpus corpus,
) {
  if (document == null) {
    return self.declares(id)
        ? SectionCitationVerdict.self
        : SectionCitationVerdict.dangling;
  }
  final target = document == self.name ? self : corpus[document];
  if (target == null) return SectionCitationVerdict.unverifiable;
  return target.declares(id)
      ? SectionCitationVerdict.crossDocument
      : SectionCitationVerdict.wrongSection;
}

/// The result of resolving a set of files.
class SectionCitationReport {
  /// Every citation found, in file then line order.
  final List<SectionCitation> citations;

  /// The files scanned.
  final List<String> files;

  /// The corpus citations resolved against.
  final SectionCorpus corpus;

  /// Creates the report.
  const SectionCitationReport({
    required this.citations,
    required this.files,
    required this.corpus,
  });

  /// The citations that must fail the check.
  List<SectionCitation> get violations =>
      [for (final c in citations) if (c.isViolation) c];

  /// Whether every citation resolves.
  bool get isClean => violations.isEmpty;

  /// How many citations carry [verdict].
  int countOf(SectionCitationVerdict verdict) =>
      citations.where((c) => c.verdict == verdict).length;
}

/// Resolves the citations of every `*.md` directly inside [docDir], against the
/// documents in that same folder.
SectionCitationReport checkSectionCitations({
  required String docDir,
  SectionCorpus? corpus,
  Iterable<String> extraFiles = const [],
}) {
  final resolved = corpus ?? SectionCorpus.loadFolder(docDir);
  final citations = <SectionCitation>[];
  final files = <String>[];

  for (final document in resolved.documents) {
    files.add(document.path);
    citations.addAll(classifySectionCitations(
      File(document.path).readAsStringSync(),
      path: document.path,
      corpus: resolved,
      own: document,
    ));
  }

  // Files outside the doc folder — project READMEs, say — cite the doc set too,
  // and a bare citation in one of them resolves against its own headings like
  // any other file.
  for (final path in extraFiles) {
    final file = File(path);
    if (!file.existsSync()) continue;
    files.add(path);
    citations.addAll(classifySectionCitations(
      file.readAsStringSync(),
      path: path,
      corpus: resolved,
    ));
  }

  return SectionCitationReport(
      citations: citations, files: files, corpus: resolved);
}
