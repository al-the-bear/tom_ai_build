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

import 'package:yaml/yaml.dart';

/// The `formatVersion` this reader understands — `kCodeSpecsExtractFormat` on
/// the emitting side.
///
/// Refusing an unknown version is the point: a later format that moved a key
/// would otherwise read as an extract with no entries, and a check with no
/// input passes.
const int kCsExtractFormat = 1;

/// The file name of the Stage-B gate record — `codespecs_prompt.md` §6.3's
/// persisted verdicts, written beside the extracts.
///
/// Detection is by basename: the record lives in the same tree as the
/// extracts, and the driver hands the reader everything it found there. The
/// name is fixed so a partial pass cannot hide its record under a name the
/// reader does not look for.
const String kCsGateRecordFile = 'gate.verdicts.yaml';

/// The `formatVersion` of the gate record this reader understands.
const int kCsGateRecordFormat = 1;

/// One of `codespecs_prompt.md` §6.2's three per-area verdicts.
enum CsGateVerdict {
  /// The extract carries every input `codespecs_derivation_contract.md` §3
  /// requires — the area is in scope.
  sufficient,

  /// The area does not apply to this project — nothing was routed, with
  /// positive evidence of absence (`codespecs_prompt.md` §6.4).
  notApplicable,

  /// The extract is missing required inputs — the run stops for this area
  /// until its L0 decision resolves. Only a recorded descope
  /// (`resolution: descoped`) legitimizes continuing without it.
  insufficient;

  /// The verdict word exactly as `codespecs_prompt.md` §6.2 states it.
  String get word => switch (this) {
        sufficient => 'sufficient',
        notApplicable => 'not applicable',
        insufficient => 'insufficient',
      };

  /// Parses a `codespecs_prompt.md` §6.2 verdict word, or returns null for an
  /// unknown one.
  static CsGateVerdict? parse(String word) => switch (word) {
        'sufficient' => sufficient,
        'not applicable' => notApplicable,
        'insufficient' => insufficient,
        _ => null,
      };
}

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

  CsExtractSet._(this.extracts, this._bySection,
      {this.excluded = const []});

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

  String? gateName;
  final extractSources = <String, String>{};
  for (final entry in sources.entries) {
    final basename = entry.key.split('/').last;
    if (basename == kCsGateRecordFile) {
      if (gateName != null) {
        throw CsExtractException(
          'both $gateName and ${entry.key} are gate records — the scope must '
          'have one author',
        );
      }
      gateName = entry.key;
    } else {
      extractSources[entry.key] = entry.value;
    }
  }

  final extracts = <CsExtract>[];
  for (final entry in extractSources.entries) {
    extracts.add(_readExtract(entry.key, entry.value));
  }

  var inScope = extracts;
  final excluded = <CsExcludedArea>[];
  if (gateName != null) {
    final verdicts = _readGateRecord(gateName, sources[gateName]!);
    final byArea = {for (final e in extracts) e.areaCode: e};
    for (final extract in extracts) {
      if (!verdicts.containsKey(extract.areaCode)) {
        throw CsExtractException(
          '$gateName carries no verdict for ${extract.areaCode} '
          '(${extract.source}) — the gate record must be total over the '
          'supplied extracts',
        );
      }
    }
    inScope = <CsExtract>[];
    for (final entry in verdicts.entries) {
      final areaCode = entry.key;
      final record = entry.value;
      final extract = byArea[areaCode];
      switch (record.verdict) {
        case CsGateVerdict.sufficient:
          if (extract != null) inScope.add(extract);
        case CsGateVerdict.notApplicable:
          if (extract != null && extract.entries.isNotEmpty) {
            throw CsExtractException(
              '$gateName marks $areaCode `not applicable`, but '
              '${extract.source} carries ${extract.entries.length} routed '
              'entr${extract.entries.length == 1 ? 'y' : 'ies'} — a routed '
              'value is evidence the area applies (codespecs_prompt.md §6.4)',
            );
          }
          excluded.add(CsExcludedArea(
            areaCode: areaCode,
            verdict: record.verdict,
            entryCount: extract?.entries.length ?? 0,
            source: extract?.source ?? '',
          ));
        case CsGateVerdict.insufficient:
          if (!record.descoped) {
            throw CsExtractException(
              '$gateName marks $areaCode `insufficient` without '
              '`resolution: descoped` — codespecs_prompt.md §6.2 says the run '
              'does not continue past an unresolved insufficient area; '
              'recording the descope is what legitimizes a partial pass',
            );
          }
          excluded.add(CsExcludedArea(
            areaCode: areaCode,
            verdict: record.verdict,
            descoped: true,
            entryCount: extract?.entries.length ?? 0,
            source: extract?.source ?? '',
          ));
      }
    }
  }

  final bySection = <String, List<CsExtractEntry>>{};
  for (final extract in inScope) {
    for (final e in extract.entries) {
      (bySection[e.sectionId] ??= <CsExtractEntry>[]).add(e);
    }
  }
  return CsExtractSet._(List.unmodifiable(inScope), bySection,
      excluded: List.unmodifiable(excluded));
}

class _CsGateEntry {
  final CsGateVerdict verdict;
  final bool descoped;
  const _CsGateEntry(this.verdict, this.descoped);
}

/// Reads the gate record into area code → verdict, validating shape.
Map<String, _CsGateEntry> _readGateRecord(String name, String yamlText) {
  final Object? document;
  try {
    document = loadYaml(yamlText);
  } on YamlException catch (e) {
    throw CsExtractException('$name is not valid YAML: ${e.message}');
  }
  if (document is! YamlMap) {
    throw CsExtractException('$name does not hold a YAML mapping');
  }
  final root = document['gate'];
  if (root is! YamlMap) {
    throw CsExtractException('$name has no top-level `gate:` mapping');
  }
  final version = root['formatVersion'];
  if (version != kCsGateRecordFormat) {
    throw CsExtractException(
      '$name declares gate record format $version; this reader understands '
      '$kCsGateRecordFormat only — reading it would silently change the scope',
    );
  }
  final verdictsNode = root['verdicts'];
  if (verdictsNode is! YamlList) {
    throw CsExtractException('$name has no `verdicts:` list');
  }
  final verdicts = <String, _CsGateEntry>{};
  for (final raw in verdictsNode) {
    if (raw is! YamlMap) {
      throw CsExtractException('$name has a verdict that is not a mapping');
    }
    final area = _string(raw['area']);
    if (area.isEmpty) {
      throw CsExtractException('$name has a verdict that names no area');
    }
    if (verdicts.containsKey(area)) {
      throw CsExtractException(
        '$name carries two verdicts for $area — a scope with two answers for '
        'one area is no scope',
      );
    }
    final verdictWord = _string(raw['verdict']);
    final verdict = CsGateVerdict.parse(verdictWord);
    if (verdict == null) {
      throw CsExtractException(
        '$name gives $area the verdict `$verdictWord` — codespecs_prompt.md '
        '§6.2 knows `sufficient`, `not applicable` and `insufficient` only',
      );
    }
    final resolution = _nullableString(raw['resolution']);
    var descoped = false;
    if (resolution != null) {
      if (verdict != CsGateVerdict.insufficient) {
        throw CsExtractException(
          '$name gives $area a `resolution:` on verdict `${verdict.word}` — '
          'only an insufficient area has an L0 decision to resolve',
        );
      }
      if (resolution != 'descoped') {
        throw CsExtractException(
          '$name gives $area the resolution `$resolution` — `descoped` is the '
          'one resolution that admits a partial pass; any other resolution '
          'means the area was completed and its verdict re-taken',
        );
      }
      descoped = true;
    }
    verdicts[area] = _CsGateEntry(verdict, descoped);
  }
  return verdicts;
}

CsExtract _readExtract(String name, String yamlText) {
  final Object? document;
  try {
    document = loadYaml(yamlText);
  } on YamlException catch (e) {
    throw CsExtractException('$name is not valid YAML: ${e.message}');
  }
  if (document is! YamlMap) {
    throw CsExtractException('$name does not hold a YAML mapping');
  }
  final root = document['extract'];
  if (root is! YamlMap) {
    throw CsExtractException('$name has no top-level `extract:` mapping');
  }

  final version = root['formatVersion'];
  if (version != kCsExtractFormat) {
    throw CsExtractException(
      '$name declares extract format $version; this reader understands '
      '$kCsExtractFormat only — reading it would silently drop entries',
    );
  }

  final area = root['area'];
  if (area is! YamlMap) {
    throw CsExtractException('$name has no `area:` mapping');
  }
  final areaCode = _string(area['code']);
  if (areaCode.isEmpty) {
    throw CsExtractException('$name names no area code');
  }

  final documentNode = root['document'];
  final documentRoot =
      documentNode is YamlMap ? _string(documentNode['root']) : '';

  final entriesNode = root['entries'];
  final entries = <CsExtractEntry>[];
  if (entriesNode is YamlList) {
    for (final raw in entriesNode) {
      if (raw is! YamlMap) {
        throw CsExtractException('$name has an entry that is not a mapping');
      }
      entries.add(
        CsExtractEntry(
          areaCode: areaCode,
          sectionId: _string(raw['sectionId']),
          path: _string(raw['path']),
          className: _string(raw['className']),
          fieldName: _string(raw['fieldName']),
          formField: _nullableString(raw['formField']),
          routedBy: _string(raw['routedBy']),
          routedAt: _string(raw['routedAt']),
          routingNote: _nullableString(raw['routingNote']),
          value: _string(raw['value']),
        ),
      );
    }
  }

  return CsExtract(
    areaCode: areaCode,
    canonicalId: _string(area['canonicalId']),
    part: _string(area['part']),
    documentRoot: documentRoot,
    catalogSource: _string(root['catalogSource']),
    entries: List.unmodifiable(entries),
    source: name,
  );
}

String _string(Object? value) => value == null ? '' : value.toString();

String? _nullableString(Object? value) => value == null ? null : '$value';

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
String csEscapeCommentLine(String line) => line
    .replaceAll('[', r'\[')
    .replaceAll(']', r'\]')
    .replaceAll('<', '&lt;');
