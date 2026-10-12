/// Reads the per-area **extract** tree — the second input the validator needs
/// to check a generated comment against the specification text it claims to
/// carry.
///
/// The trio alone cannot answer "did this sentence come from the
/// specification". `codespecs_mapping.md` §1.1.1 makes the extract the artifact
/// that carries the other side: one `<CE-CODE>.extract.yaml` per active area,
/// holding every routed value **verbatim**, keyed by section id. That is
/// exactly the shape the comment rules need —
/// `codespecs_derivation_contract.md` §2.8 C1 says a comment's text comes from
/// a contributing section, and C4.2 says each line is its source line rather
/// than a re-wrap of it, so both questions reduce to a lookup by section id
/// followed by a string comparison.
///
/// The reader is deliberately its own unit rather than a private helper of the
/// checks: the extract tree is the input for coverage questions too, and one
/// parser read by two consumers cannot disagree with itself about what an
/// extract says.
library;

import 'dart:convert';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The `formatVersion` this reader understands — the runtime's
/// [kCodeSpecsExtractFormat]; the runtime owns the one reader.
const int kCsExtractFormat = kCodeSpecsExtractFormat;

/// The file name of the Stage-B gate record — the runtime's
/// [kCodeSpecsGateRecordFile].
const String kCsGateRecordFile = kCodeSpecsGateRecordFile;

/// The `formatVersion` of the gate record — the runtime's
/// [kCodeSpecsGateRecordFormat].
const int kCsGateRecordFormat = kCodeSpecsGateRecordFormat;

/// One of `codespecs_prompt.md` §6.2's three per-area verdicts — the
/// runtime's [CodeSpecsGateVerdict].
typedef CsGateVerdict = CodeSpecsGateVerdict;

/// One area the gate record excluded from the obligation set.
///
/// The extract itself is dropped from [CsExtractSet.extracts] — the authoring
/// agent never read it, so no check may treat its tokens as available or
/// obligatory — but the exclusion is kept visible so the driver can announce
/// it: a scoped-out area must never read as a covered one.
class CsExcludedArea {
  /// The `CE-*` code.
  final String areaCode;

  /// The recorded verdict — [CsGateVerdict.notApplicable] or
  /// [CsGateVerdict.insufficient] (a sufficient area is never excluded).
  final CsGateVerdict verdict;

  /// Whether an insufficient verdict was resolved by descoping. Always true
  /// for insufficient entries that pass validation; false for not-applicable.
  final bool descoped;

  /// How many routed entries the excluded extract carried (0 when the record
  /// names an area with no extract file).
  final int entryCount;

  /// Where the excluded extract was read from, or '' when there was none.
  final String source;

  /// Creates the record.
  const CsExcludedArea({
    required this.areaCode,
    required this.verdict,
    this.descoped = false,
    this.entryCount = 0,
    this.source = '',
  });
}

/// A malformed or unreadable extract.
class CsExtractException implements Exception {
  /// What is wrong.
  final String message;

  /// Creates the exception.
  const CsExtractException(this.message);

  @override
  String toString() => 'CsExtractException: $message';
}

/// One routed value of one section.
class CsExtractEntry {
  /// The `CE-*` code of the area this entry was routed to.
  final String areaCode;

  /// The section id the value belongs to — the key a `DocRef` names.
  final String sectionId;

  /// The enclosing section instance's headline, copy-only: the stored
  /// headline, else the `@Headline` type default, else null.
  final String? headline;

  /// The nearest enclosing list-item instance's **stored** section id — the
  /// `<!--[…]-->` id the document serializes — or null when no enclosing
  /// instance stores one. Copy-only auxiliary trace data; a `DocRef` still
  /// names the extract token, not this id (`codespecs_mapping.md` §9.3).
  final String? instanceId;

  /// The document path of the node the value was read from.
  final String path;

  /// The model class that declared it.
  final String className;

  /// The model field that held it.
  final String fieldName;

  /// The `@Form` field label, when the value is one field of a form section.
  final String? formField;

  /// The annotation that routed the section to the area.
  final String routedBy;

  /// Where the routing annotation sits.
  final String routedAt;

  /// The routing annotation's note, when it carries one.
  final String? routingNote;

  /// The stored value, verbatim as the specification holds it.
  final String value;

  /// Creates an entry.
  const CsExtractEntry({
    required this.areaCode,
    required this.sectionId,
    required this.value,
    this.headline,
    this.instanceId,
    this.path = '',
    this.className = '',
    this.fieldName = '',
    this.formField,
    this.routedBy = '',
    this.routedAt = '',
    this.routingNote,
  });

  /// [value] split into lines, exactly as authored.
  List<String> get rawLines => const LineSplitter().convert(value);

  /// [value] split into lines with `codespecs_derivation_contract.md` §2.8
  /// C4.4's two escapes applied.
  ///
  /// A comment line may legitimately appear in either form: C4.4 requires the
  /// escaped one, and check 27 owns that requirement. Offering both lets the
  /// comment checks speak about *source* and *fidelity* without also
  /// re-reporting an escaping failure — one rule, one check.
  List<String> get escapedLines => csEscapedLines(value);

  /// Where the value came from, for a violation message.
  String get origin =>
      formField == null ? '$className.$fieldName' : '$className.$formField';
}

/// One area's extract.
class CsExtract {
  /// The `CE-*` code.
  final String areaCode;

  /// The `codespecs_mapping.md` §4.1 canonical id.
  final String canonicalId;

  /// The `@CodeSpecKind` value.
  final String part;

  /// The section segment of the document root the entries were collected from.
  final String documentRoot;

  /// The `codespecs_mapping.md` source the catalogue was transcribed from.
  final String catalogSource;

  /// The routed entries, in SOM document order.
  final List<CsExtractEntry> entries;

  /// Where this extract was read from, for a violation message.
  final String source;

  /// Creates an extract.
  const CsExtract({
    required this.areaCode,
    this.canonicalId = '',
    this.part = '',
    this.documentRoot = '',
    this.catalogSource = '',
    this.entries = const [],
    this.source = '',
  });
}

/// Every extract the caller supplied, indexed by section id.
///
/// When a gate record ([kCsGateRecordFile]) is among the sources, the set is
/// **scoped**: [extracts] holds the areas the record marked `sufficient` only,
/// and [excluded] carries the rest. Every consumer — coverage, comment
/// fidelity, self-sufficiency — therefore sees the same scope by construction;
/// no check needs its own filtering.
class CsExtractSet {
  /// The in-scope extracts, in the order they were read.
  final List<CsExtract> extracts;

  /// The areas a gate record excluded — empty when no record was supplied.
  final List<CsExcludedArea> excluded;

  final Map<String, List<CsExtractEntry>> _bySection;

  CsExtractSet._(this.extracts, this._bySection, {this.excluded = const []});

  /// An empty set — the state every check treats as "no second input", so a
  /// caller that supplied no extracts sees the trio-only checks and nothing
  /// else.
  static final CsExtractSet empty = CsExtractSet._(const [], const {});

  /// Whether any extract was supplied.
  bool get isEmpty => extracts.isEmpty;

  /// The document roots the extracts were collected from.
  Set<String> get documentRoots =>
      {for (final e in extracts) e.documentRoot}..removeWhere((r) => r.isEmpty);

  /// Every entry across every extract.
  Iterable<CsExtractEntry> get entries => extracts.expand((e) => e.entries);

  /// The section ids the extracts know about.
  Iterable<String> get sectionIds => _bySection.keys;

  /// Whether any extract routed a value of [sectionId].
  bool knowsSection(String sectionId) => _bySection.containsKey(sectionId);

  /// The values routed from [sectionId], across every area.
  List<CsExtractEntry> entriesFor(String sectionId) =>
      _bySection[sectionId] ?? const [];

  /// The values routed from any of [sectionIds], in the given order.
  List<CsExtractEntry> entriesForAll(Iterable<String> sectionIds) => [
    for (final id in sectionIds) ...entriesFor(id),
  ];
}

/// Reads [sources] — file name → YAML text — into a [CsExtractSet].
///
/// The keys are only used to name a source in a violation message and to
/// recognise the gate record by basename; the area code comes from the
/// document, so a renamed file cannot silently change what an extract is
/// taken to be.
///
/// When one source's basename is [kCsGateRecordFile], it is read as the
/// Stage-B gate record (`codespecs_prompt.md` §6.3) and the set is scoped by
/// it: an area is in scope **iff** its verdict is `sufficient`. The record
/// must be total over the supplied extracts — an extract whose area carries no
/// verdict is an error, because a scope that is silent about an area would let
/// a skipped area read as a passed one. A `not applicable` area whose extract
/// has entries contradicts the evidence-of-absence rule of
/// `codespecs_prompt.md` §6.4 and is an error; an `insufficient` area without
/// `resolution: descoped` is an error, because §6.2 of `codespecs_prompt.md`
/// says the run may not have continued past it — recording the descope is the
/// act that legitimizes the partial pass.
CsExtractSet readCsExtracts(Map<String, String> sources) {
  if (sources.isEmpty) return CsExtractSet.empty;
  final CodeSpecsExtractSet read;
  try {
    read = CodeSpecsExtractSet.fromFiles(sources);
  } on CodeSpecsRecordError catch (e) {
    throw CsExtractException(e.message);
  }
  final inScope = <CsExtract>[
    for (var i = 0; i < read.extracts.length; i++)
      _fromRuntime(read.extracts[i], read.sources[i]),
  ];
  final bySection = <String, List<CsExtractEntry>>{};
  for (final extract in inScope) {
    for (final e in extract.entries) {
      (bySection[e.sectionId] ??= <CsExtractEntry>[]).add(e);
    }
  }
  return CsExtractSet._(
    List.unmodifiable(inScope),
    bySection,
    excluded: List.unmodifiable([
      for (final x in read.excluded)
        CsExcludedArea(
          areaCode: x.area,
          verdict: x.verdict,
          descoped: x.descoped,
          entryCount: x.entryCount,
          source: x.source,
        ),
    ]),
  );
}

CsExtract _fromRuntime(CodeSpecsExtract x, String source) => CsExtract(
  areaCode: x.area.code,
  canonicalId: x.area.canonicalId,
  part: x.area.part,
  documentRoot: x.documentRoot,
  catalogSource: x.catalogSource,
  source: source,
  entries: List.unmodifiable([
    for (final e in x.entries)
      CsExtractEntry(
        areaCode: e.areaCode,
        sectionId: e.sectionId,
        headline: e.headline,
        instanceId: e.instanceId,
        path: e.path,
        className: e.className,
        fieldName: e.fieldName,
        formField: e.formField,
        routedBy: e.routedBy,
        routedAt: e.routedAt,
        routingNote: e.routingNote,
        value: e.value,
      ),
  ]),
);

/// [text] split into lines with `codespecs_derivation_contract.md` §2.8 C4.4's
/// two escapes applied — `[` → `\[`, `]` → `\]`, `<` → `&lt;`.
///
/// Escaping is skipped inside fenced code blocks, and a fence line is copied
/// through unchanged, exactly as C4.4 states it: escaping a fence's contents
/// would show the escape.
List<String> csEscapedLines(String text) {
  final out = <String>[];
  var fenced = false;
  for (final line in const LineSplitter().convert(text)) {
    if (line.trimLeft().startsWith('```')) {
      fenced = !fenced;
      out.add(line);
      continue;
    }
    out.add(fenced ? line : csEscapeCommentLine(line));
  }
  return out;
}

/// One line with C4.4's escapes applied.
String csEscapeCommentLine(String line) =>
    line.replaceAll('[', r'\[').replaceAll(']', r'\]').replaceAll('<', '&lt;');
