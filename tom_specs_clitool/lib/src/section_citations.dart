/// Resolves the `§`-citations in the TomSpecs documents, so `index.md`'s
/// citation convention can be decided by a program rather than by a reader.
///
/// ## Why this exists
///
/// The convention used to say that a bare `§N` — a section sign with no
/// document in front of it — is unresolvable and always a defect. Taken
/// literally that condemned some sixteen hundred sites: intra-document
/// self-reference is pervasive and idiomatic across the doc set, and one
/// document had already declared a private carve-out for itself. The convention
/// as written was not the convention as practised, and while that gap stood no
/// mechanical check was possible — a checker could not tell a legitimate
/// self-citation from a citation that had lost its document.
///
/// `index.md` now carves the self-reference out explicitly: a bare `§N` means
/// *this document*. That single change makes the rule decidable, and this
/// library is the decision procedure:
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
/// - **The run.** Documents write `§4.1 / §4.2 / §4.3` and `(§5.2, §5.8)`; <!-- section-cite: exhibit 4.1 4.2 4.3 5.2 5.8 -->
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
/// ## Citations that are not of this doc set
///
/// `§` is not a TomSpecs sign. The doc set traces its structure to public
/// standards and cites their clauses in their own notation —
/// `ISO/IEC/IEEE 29148 §6`, `ISO/IEC 25010:2023 §4.2` — and a rule that knew
/// nothing of them read those as bare and resolved them against the citing
/// document. That is worse than a false alarm: `tom_specs_model_rules.md`
/// cites ISO 29148 §6 and itself declares a `tom_specs_model_rules.md` §6, so
/// the citation was passing as a *correct* self-reference while pointing a
/// reader at the wrong document entirely.
///
/// So a citation governed by a **standard designator** — a recognised issuing
/// body, or several slash-joined, followed by the standard's number
/// ([_standardsBodies]) — is qualified by that designator and reported
/// [SectionCitationVerdict.unverifiable], the verdict that already means "named
/// a document this checker cannot see". The body list is closed and short:
/// these are standards organisations, admitting one is a deliberate edit, and
/// keying on a shape instead would let any pair of capitals followed by a
/// number vouch for a citation.
///
/// ## Resolution is exact
///
/// An id resolves when a heading **declares** it — not when an ancestor or a
/// descendant does. Both relaxations were tried against the real doc set and
/// both hide real defects: resolving `§5.23` through an existing `§5` <!-- section-cite: exhibit 5.23 5 -->
/// would excuse a hundred citations that belong to another document, and it
/// cannot be distinguished from the genuine case (`§12.3.6` naming rule 6 <!-- section-cite: exhibit 12.3.6 -->
/// inside a section with no `12.3.x` headings) by anything a parser can see. So
/// a citation that addresses a numbered item rather than a heading says so in
/// words — "rule 6 of `§12.3`" — and a citation written as a section number has <!-- section-cite: exhibit 12.3 -->
/// to be one.
///
/// (Those four signs are specimens of the syntax, not references, so each line
/// carries a marker naming exactly the ids it exhibits — see below.)
///
/// ## What counts as a citation
///
/// A section id is either a **dotted number** (`5.23`, `10.2`) or an
/// **upper-case symbolic id** (`PF-DOC-PUR` — `tom_specs_project_flow.md`
/// numbers its headings that way). Everything else after a `§` is not a
/// citation: `§oneof`, `§item` and `§content` are DocSpecs section-type names,
/// and the `§N` of the convention's own prose is a metavariable. Keying on the
/// *shape* of the id rather than on a list of exceptions means a new document
/// using either scheme is covered on the day it is written.
///
/// ## Exhibits: the one thing that looks like a citation and is not
///
/// A file that *documents* the citation convention has to show it. This library
/// writes `` `§4.1 / §4.2 / §4.3` `` to explain the run rule, and <!-- section-cite: exhibit 4.1 4.2 4.3 -->
/// `codespecs_mapping.md` shows the shapes it defines. Those signs are
/// metavariables — they name the syntax, not a section — and no rule of shape
/// tells them from the real thing, because they are deliberately identical to
/// it. Hence the one exemption this gate admits:
///
/// ```text
/// <!-- section-cite: exhibit 4.1 4.2 4.3 -->
/// ```
///
/// **It is scoped to the line and to the ids it names**, and both halves are
/// load-bearing. Line scope, because the file that explains the convention
/// still *uses* it: the paragraph above cites `tom_specs_model_rules.md` §6 for
/// real, two lines from an exhibit. Id scope, because a marker that exempted
/// the line wholesale would swallow the next citation added beside the exhibit
/// — and that citation would then be wrong in silence, which is the failure the
/// gate exists to prevent. There is deliberately **no document-level marker**:
/// the todo-citation gate has one because a history document has no live claims
/// at all, whereas a file explaining a convention makes live claims throughout.
///
/// The ids are written **without the `§`** so the marker cannot itself be read
/// as a citation, and a marker naming an id that nothing on its line needed is
/// reported ([StaleSectionExemption]) rather than left to rot — an exemption
/// outliving its exhibit is the same silent decay in the other direction.
///
/// ## What it does *not* do
///
/// It checks that a citation **resolves**, not that it is **apt** —
/// `index.md`'s "cite by subject, not by number" is a rule for humans, and a
/// number that resolves to the wrong heading looks identical to one that
/// resolves to the right heading. The mechanical half is the half that decays
/// silently.
///
/// A qualified citation naming a document outside the corpus is reported as
/// [SectionCitationVerdict.unverifiable] rather than as a defect: the checker
/// cannot see the file, which is not the same as the citation being wrong.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The shape of a section id: a dotted number, or an upper-case symbolic id.
///
/// Both schemes are in use — `codespecs_mapping.md` numbers its headings
/// `4.1.2`, `tom_specs_project_flow.md` names its own `PF-FLW-OVE`.
const String sectionIdPattern = r'(?:\d+(?:\.\d+)*|[A-Z]{2,}(?:-[A-Z0-9]+)+)';

/// A `§` followed by an optional space and a section id.
final RegExp _citation = RegExp('§[  ]?($sectionIdPattern)');

/// An exhibit marker, capturing the whitespace-separated ids it names.
///
/// `[^>]*?` rather than `.*?` so an unterminated marker cannot run to the next
/// one several lines down — the payload is confined to what precedes the first
/// `>`, and a marker is a single-line construct.
final RegExp _exhibitMarker =
    RegExp(r'<!--\s*section-cite:\s*exhibit([^>]*?)-->');

/// A token of an exhibit marker's payload, anchored so a partial id is
/// rejected.
final RegExp _exhibitId = RegExp('^$sectionIdPattern\$');

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
/// Accepts the file name bare, in backticks, or as the tail of a markdown link
/// — hence the `)` among the characters skipped — and accepts `SOM`, the short
/// form the convention reserves for `som_multiplatform_spec_model.md` because
/// those citations appear inside fixed-width comment banners in generated
/// source.
final RegExp _leadingQualifier =
    RegExp(r'(?:([A-Za-z0-9_.-]+\.md)|\bSOM)[`*_)\]\s ]*$');

/// The standards bodies whose clause citations the doc set makes.
///
/// Closed, and deliberately so — a standards organisation is a named thing, and
/// admitting one is an edit reviewed as such. The alternative, keying on the
/// shape "capitals then a number", would let `CE-ER 5` qualify a citation.
const _standardsBodies = [
  'ISO',
  'IEC',
  'IEEE',
  'ITU',
  'RFC',
  'W3C',
  'WCAG',
  'NIST',
  'OWASP',
  'OMG',
  'ANSI',
  'ETSI',
  'DIN',
  'BSI',
];

/// A public-standard designator standing immediately before a `§` —
/// `ISO/IEC/IEEE 29148 §6`, `RFC 7519 §4.1`.
///
/// The number is required. Without it `ISO §4` would match, and a bare body <!-- section-cite: exhibit 4 -->
/// name is a mention of an organisation rather than a citation of one of its
/// standards.
final RegExp _externalStandardQualifier = RegExp(
  '\\b((?:${_standardsBodies.join('|')})'
  '(?:/(?:${_standardsBodies.join('|')}))*'
  '[  ]+[0-9][0-9A-Za-z:._-]*)[`*_\\s ]*\$',
);

/// A document name standing just after a citation — `§11 of `x.md``.
final RegExp _trailingQualifier =
    RegExp(r'^[\s ]+(?:of|in)[\s ]+[`*_(\[]*([A-Za-z0-9_.-]+\.md)');

/// A table cell holding a document reference **and nothing else**.
final RegExp _documentOnlyCell = RegExp(
    r'^[\s`*_]*(?:\[[^\]]*\]\(\s*)?([A-Za-z0-9_.-]+\.md)(?:\s*\))?[\s`*_]*$');

/// A table **header** cell holding a document reference and nothing else but an
/// optional bare `§` — `` `llm_and_d4rt_tools.md` § ``.
///
/// The trailing sign is what makes the header say "this column holds sections
/// of that document" rather than merely mentioning it, so it is admitted here
/// and nowhere else.
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
/// TomSpecs, and their unrelated `§` usage would have to be exempted one by
/// one.
///
/// The **todo** gate holds the same set — a README pointing at a finished or an
/// ambiguous todo strands its reader exactly as a doc-folder page does, and the
/// two gates asking about the same files is the point of there being one list
/// rather than two that drift.
const defaultCitedReadmes = [
  'tom_ai/ai_build/tom_code_specs/README.md',
  'tom_ai/ai_build/tom_spec_engine/README.md',
  'tom_ai/ai_build/tom_specs_clitool/README.md',
  'tom_ai/ai_build/tom_specs_core/README.md',
  'tom_ai/ai_build/tom_specs_model/README.md',
  'tom_ai/core/tom_core_codespecs/README.md',
];

/// The source trees whose doc comments cite the doc set,
/// container-root-relative.
///
/// A package's doc comments are the first thing a reader of that package sees,
/// and they cite the doc set by section exactly as the documents do — so they
/// decay in exactly the same silence. A gate that read `.md` alone would hold
/// the documents to the convention and leave the source that cites them
/// unchecked, which is the half a reader meets first.
///
/// **Roots are enumerated; files beneath them are discovered.** The two halves
/// answer different risks. Enumerating the roots keeps the gate's subject
/// coherent — these are the TomSpecs source trees that cite the doc set, and a
/// workspace-wide sweep for Dart files would pull in projects whose unrelated
/// `§` usage would need exempting one by one. Discovering the files beneath
/// them means a new annotation file is covered the day it is added, rather than
/// the day someone remembers to list it.
///
/// The membership rule is *citing*, not *kind*. The three CodeSpecs packages
/// came first because the framework's annotations are almost nothing but
/// citations; but the model, the tooling and the engine cite the same fourteen
/// documents just as densely — a little over two hundred citations between them
/// — and a rule that admitted only the framework would have left the larger half
/// of the corpus decaying in the silence this gate exists to break.
const defaultCitedSourceRoots = [
  'tom_ai/ai_build/tom_code_specs/lib',
  'tom_ai/ai_build/tom_spec_engine/lib',
  'tom_ai/ai_build/tom_specs_clitool/lib',
  'tom_ai/ai_build/tom_specs_core/lib',
  'tom_ai/ai_build/tom_specs_model/lib',
  'tom_ai/core/tom_core_codespecs/lib',
];

/// Every `.dart` file under [root], recursively, in path order.
List<String> listDartSources(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path)
      .where((path) => p.extension(path) == '.dart')
      .toList()
    ..sort();
}

/// Lifts the `///` doc comments of [source] out of the Dart around them.
///
/// A Dart doc comment *is* markdown, so the resolver needs no second set of
/// rules — it needs the markdown handed to it without the `///`. Two properties
/// make the lift worth doing rather than scanning the raw file:
///
/// - **Line count is preserved**, so a violation is still reported at the line a
///   reader will open.
/// - **Non-doc lines become empty**, which does two jobs at once. It keeps `§`
///   inside a `//` note or a string literal out of the scan — neither is read by
///   a reader following a citation — and it makes each declaration's doc comment
///   its own block, so the lookback for a document name cannot reach back past
///   the declaration above.
///
/// Without the lift, a citation whose document name wrapped onto the previous
/// line would read as bare: the lookback crosses a soft wrap but not a `///`.
/// Only `///` is lifted; these packages document with it exclusively, and a
/// `/** */` block would need brace tracking to no benefit.
String dartDocComments(String source) {
  final lines = source.split('\n');
  return [
    for (final line in lines)
      _docLine.firstMatch(line)?.group(1) ?? '',
  ].join('\n');
}

/// A `///` documentation line, capturing what follows the marker.
final RegExp _docLine = RegExp(r'^\s*///[ \t]?(.*)$');

/// Text that joins two citations of one run rather than separating two
/// thoughts.
///
/// Deliberately short: whitespace and the punctuation that enumerates or
/// ranges. `and`, `to` and `through` are in because the documents write
/// `§4.1 and §4.2`; an em dash is out because it opens a clause, and a `|` is <!-- section-cite: exhibit 4.1 4.2 -->
/// out because it ends a table cell.
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

  /// A public-standard designator stands immediately before it — the citation
  /// is of a standard's clause, not of a document in this set.
  externalStandard,

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

/// Why a `§` that resolves to no heading is nonetheless not a defect.
///
/// One member, and the set is meant to stay small: each addition is a class of
/// sign the gate agrees not to see, so each has to earn its place by naming a
/// construct that is *provably* not a citation rather than one that is merely
/// inconvenient.
enum SectionCitationExemption {
  /// `<!-- section-cite: exhibit … -->` — the ids the marker names on this line
  /// are specimens of the citation syntax, written by a file that documents the
  /// convention. A metavariable, not a reference.
  ///
  /// The ids stand as `…` here rather than as real ones so this comment is a
  /// *description* of the marker and not an instance of it — a live marker
  /// naming ids the line does not carry is exactly what
  /// [StaleSectionExemption] reports. The library doc shows the real shape,
  /// inside a fence, where it is inert for the same reason.
  exhibit,
}

/// An exhibit marker that suppressed nothing.
///
/// Reported as a defect for the same reason a dangling citation is: it is a
/// claim about the line that has stopped being true, and nothing else would
/// ever notice. The usual cause is an exhibit edited away while its marker
/// stayed.
class StaleSectionExemption {
  /// Path of the file the marker is in.
  final String file;

  /// 1-based line number of the marker.
  final int line;

  /// The id the marker named and nothing on the line needed.
  final String id;

  /// Creates the report entry.
  const StaleSectionExemption({
    required this.file,
    required this.line,
    required this.id,
  });

  /// A one-line, `file:line`-prefixed description suitable for a build log.
  String describe({String? relativeTo}) {
    final where = relativeTo == null ? file : p.relative(file, from: relativeTo);
    return '$where:$line: §$id — STALE EXEMPTION — nothing on this line needs '
        'it; drop the id from the marker';
  }
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

  /// The marker that excuses an unresolved verdict, or `null`.
  ///
  /// Set only when the verdict is one the exemption could excuse, so an
  /// exemption naming an id that resolves anyway is left unconsumed and
  /// surfaces as a [StaleSectionExemption].
  final SectionCitationExemption? exemption;

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
    this.exemption,
  });

  /// True when the citation must fail the check.
  bool get isViolation => _unresolved && exemption == null;

  bool get _unresolved =>
      verdict == SectionCitationVerdict.dangling ||
      verdict == SectionCitationVerdict.wrongSection;

  /// A one-line, `file:line`-prefixed description suitable for a build log.
  String describe({String? relativeTo}) {
    final where = relativeTo == null ? file : p.relative(file, from: relativeTo);
    final excused = exemption == null ? '' : ' [${exemption!.name}]';
    return '$where:$line: §$id — ${_reason()}$excused';
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

/// The exhibit ids each line exempts, keyed by 1-based line number.
///
/// Markers inside a fence are ignored, so this library's own fenced example of
/// the marker syntax stays inert — a fence holds specimens, and a specimen
/// marker that took effect would be reported stale for exempting nothing.
Map<int, Set<String>> _exhibitsByLine(List<String> lines) {
  final byLine = <int, Set<String>>{};
  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    if (_fence.hasMatch(lines[i])) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    for (final marker in _exhibitMarker.allMatches(lines[i])) {
      for (final token in marker.group(1)!.split(RegExp(r'\s+'))) {
        // A token that is not an id is dropped rather than reported: the
        // exhibit it was meant to cover then stays a violation, which says the
        // same thing at the place a reader can act on it.
        if (_exhibitId.hasMatch(token)) (byLine[i + 1] ??= {}).add(token);
      }
    }
  }
  return byLine;
}

/// The exhibit ids [markdown] declares but no citation on their line consumed.
///
/// Recomputed from the text rather than threaded out of
/// [classifySectionCitations], so the resolver's signature stays the one thing
/// callers already know and the staleness question is asked by whoever cares.
List<StaleSectionExemption> staleSectionExemptions(
  String markdown, {
  required String path,
  required List<SectionCitation> citations,
}) {
  final declared = _exhibitsByLine(markdown.split('\n'));
  for (final citation in citations) {
    if (citation.exemption == null) continue;
    declared[citation.line]?.remove(citation.id);
  }
  return [
    for (final entry in declared.entries)
      for (final id in entry.value)
        StaleSectionExemption(file: path, line: entry.key, id: id),
  ]..sort((a, b) =>
      a.line != b.line ? a.line.compareTo(b.line) : a.id.compareTo(b.id));
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

  final lines = markdown.split('\n');
  final exhibits = _exhibitsByLine(lines);
  final blocks = _blocksOf(lines);
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
      final external = _externalStandardQualifier.firstMatch(before);
      final trailing = _trailingQualifier.firstMatch(after);
      if (leading != null) {
        document = leading.group(1) ?? somDocument;
        viaShortForm = leading.group(1) == null;
        source = SectionQualifierSource.leading;
      } else if (external != null) {
        document = external.group(1)!.replaceAll(RegExp(r'[  ]+'), ' ');
        source = SectionQualifierSource.externalStandard;
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

      final id = match.group(1)!;
      final line = block.lineAt(match.start);
      final verdict = _verdictFor(id, document, self, corpus);
      // The exemption is consumed only by a verdict it could excuse, so a
      // marker naming an id that resolves anyway stays unconsumed and is
      // reported stale rather than quietly attaching to a healthy citation.
      final excusable = verdict == SectionCitationVerdict.dangling ||
          verdict == SectionCitationVerdict.wrongSection;

      citations.add(SectionCitation(
        id: id,
        document: document,
        source: source,
        viaShortForm: viaShortForm,
        file: path,
        line: line,
        context: block.text.split('\n')[line - block.firstLine],
        verdict: verdict,
        exemption: excusable && (exhibits[line]?.contains(id) ?? false)
            ? SectionCitationExemption.exhibit
            : null,
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

  /// Exhibit markers that excused nothing.
  final List<StaleSectionExemption> staleExemptions;

  /// Creates the report.
  const SectionCitationReport({
    required this.citations,
    required this.files,
    required this.corpus,
    this.staleExemptions = const [],
  });

  /// The citations that must fail the check.
  List<SectionCitation> get violations =>
      [for (final c in citations) if (c.isViolation) c];

  /// The citations an exhibit marker excused.
  List<SectionCitation> get exempted =>
      [for (final c in citations) if (c.exemption != null) c];

  /// Whether every citation resolves and every exemption still earns its keep.
  bool get isClean => violations.isEmpty && staleExemptions.isEmpty;

  /// How many citations carry [verdict].
  int countOf(SectionCitationVerdict verdict) =>
      citations.where((c) => c.verdict == verdict).length;
}

/// Resolves the citations of every `*.md` directly inside [docDir], against the
/// documents in that same folder.
///
/// [extraFiles] are markdown outside the folder — project READMEs.
/// [extraSources] are Dart files, whose `///` comments are lifted by
/// [dartDocComments] before they are resolved.
SectionCitationReport checkSectionCitations({
  required String docDir,
  SectionCorpus? corpus,
  Iterable<String> extraFiles = const [],
  Iterable<String> extraSources = const [],
}) {
  final resolved = corpus ?? SectionCorpus.loadFolder(docDir);
  final citations = <SectionCitation>[];
  final stale = <StaleSectionExemption>[];
  final files = <String>[];

  // Resolves one file's already-prepared markdown and folds both results in —
  // citations and the exemptions none of them consumed.
  void scan(String markdown, {required String path, DocumentSections? own}) {
    files.add(path);
    final found = classifySectionCitations(markdown,
        path: path, corpus: resolved, own: own);
    citations.addAll(found);
    stale.addAll(
        staleSectionExemptions(markdown, path: path, citations: found));
  }

  for (final document in resolved.documents) {
    scan(File(document.path).readAsStringSync(),
        path: document.path, own: document);
  }

  // Files outside the doc folder — project READMEs, say — cite the doc set too,
  // and a bare citation in one of them resolves against its own headings like
  // any other file.
  for (final path in extraFiles) {
    final file = File(path);
    if (!file.existsSync()) continue;
    scan(file.readAsStringSync(), path: path);
  }

  // Source files carry citations in their doc comments. `own` is stated
  // empty rather than inferred: a Dart file declares no sections, so the
  // self-reference carve-out has nothing to resolve against and every citation
  // in source must name its document.
  for (final path in extraSources) {
    final file = File(path);
    if (!file.existsSync()) continue;
    scan(dartDocComments(file.readAsStringSync()),
        path: path,
        own: DocumentSections(
            path: path, name: p.basename(path), byId: const {}));
  }

  return SectionCitationReport(
    citations: citations,
    files: files,
    corpus: resolved,
    staleExemptions: stale,
  );
}
