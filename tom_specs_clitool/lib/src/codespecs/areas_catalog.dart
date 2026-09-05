/// Builds the machine-readable **CodeSpecs area catalogue** — the input the
/// nine-runtime `spec_codespecs_extract` surface reads — by transcribing
/// `codespecs_mapping.md` §4.1, §4.4.3 and §4.4.6.
///
/// The catalogue is *derived*, never authored: `codespecs_mapping.md` §4.1 is
/// the document that declares itself authoritative ("the `CodeSpecPart` enum is
/// generated from this table"), so a second hand-kept copy of those 26 rows
/// would be a second thing to keep current — and the one failure mode this
/// quest has met three times is a vocabulary duplicated N ways that is wrong in
/// agreement. Every cell this builder emits is copied out of the document
/// character for character; the only judgement it makes is which cell goes in
/// which slot.
///
/// The one thing it cannot read off a table is the across-slice **cites**
/// relation: `codespecs_mapping.md` §4.4.3 states it in the prose paragraph
/// "Why this order (the across-slice edges it satisfies)", and that paragraph
/// contains sentences a regex reads backwards ("5 cites 1 and 2 **and never 3
/// or 4**"). So the seven edge lists are transcribed as [kSliceCites] and
/// guarded *structurally* instead — see [_checkCites].
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The `codespecs_mapping.md` §4.4.3 across-slice edges, transcribed from the
/// "Why this order" prose.
///
/// Not parsed, because the paragraph states one of them by negation. Guarded by
/// [_checkCites]: every edge must point strictly backwards, and the
/// `codespecs_mapping.md` §4.4.6 authoring serialisation must be a topological
/// order of the relation. A transcription slip that matters shows up as one of
/// those failing.
const Map<int, List<int>> kSliceCites = {
  1: [],
  2: [1],
  3: [1, 2],
  4: [1, 2, 3],
  5: [1, 2],
  6: [1, 5],
  7: [3, 4],
};

/// The `codespecs_mapping.md` §4.4.6 rule-1 slice serialisation. Used only as a
/// check on [kSliceCites].
const List<int> kAuthoringSliceOrder = [1, 2, 3, 4, 7, 5, 6];

/// The `codespecs_mapping.md` §4.1 member-kind extract home **CE-EN** —
/// the one areas-catalogue entry that is not a parts-catalogue row.
///
/// `domainEnum` is a member kind, so `codespecs_mapping.md` §4.1's table (and
/// its 26-row count) does not carry it; but its values (`DOMEN`/`DMENE`/
/// `DMEVA`) route via `@CodeSpecKind([CodeSpecPart.domainEnum])` and need an
/// extract of their own for authoring step 1 of `codespecs_mapping.md` §4.4.6
/// — that is the `codespecs_mapping.md` §4.1 member-kind rule bullet this
/// entry transcribes. Like [kSliceCites] it is transcribed rather than parsed (the
/// rule is prose, not a table) and guarded structurally instead:
/// [_checkStepCoverage] requires its steps to be **exactly** the steps the
/// `codespecs_mapping.md` §4.4.6 coverage partition leaves unclaimed, and
/// [buildAreasCatalog] requires its kind and code to collide with no parsed
/// part's.
const Map<String, dynamic> kMemberKindArea = {
  'code': 'CE-EN',
  'canonicalId': 'DomainEnum',
  'part': 'domainEnum',
  'annotations': ['CsEnum'],
  'builtOn':
      'Plain Dart `enum` — a member kind, not a part: no `tom_core` basis and '
          'no gap class (§4.1 member-kind rule; '
          '`codespecs_derivation_contract.md` §3.1.1)',
  'attributeSurface': '§4.1',
  'slices': [1],
  'authoringSteps': [1],
  'active': true,
};

/// A failure to transcribe the mapping document — a missing table, a row that
/// does not parse, or a cross-table disagreement.
class AreasCatalogException implements Exception {
  final String message;
  const AreasCatalogException(this.message);
  @override
  String toString() => 'AreasCatalogException: $message';
}

/// The transcribed catalogue, ready to serialize.
class AreasCatalog {
  /// Where it came from, for the extract header — `codespecs_mapping.md §4.1 …`.
  final String source;

  /// The slices of `codespecs_mapping.md` §4.4.3, in emission order.
  final List<Map<String, dynamic>> slices;

  /// The areas of `codespecs_mapping.md` §4.1, in catalogue order — which is
  /// rule 2's tie-break in §4.4.6 of `codespecs_mapping.md`, so it is
  /// load-bearing rather than cosmetic.
  final List<Map<String, dynamic>> areas;

  const AreasCatalog({
    required this.source,
    required this.slices,
    required this.areas,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'slices': slices,
        'areas': areas,
      };

  /// The JSON text written to disk — two-space indented, newline-terminated,
  /// so a regeneration diff reads line by line.
  String toJsonText() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';
}

/// Transcribes [mappingDocument] (the text of `codespecs_mapping.md`).
AreasCatalog buildAreasCatalog(String mappingDocument) {
  final lines = const LineSplitter().convert(mappingDocument);

  final parts = _parsePartsCatalogue(lines);
  final sliceRows = _parseSliceTable(lines);
  final stepSlices = _parseStepTable(lines);
  final areaSteps = _parseCoverage(lines);
  final surfaces = _parseAttributeSurfaces(lines);

  _checkCites(sliceRows.keys.toList()..sort());

  // CE-EN, the `domainEnum` member-kind extract home (`codespecs_mapping.md`
  // §4.1 rule bullet), leads the catalogue: §4.4.6 gives the member kind
  // position 0 ("everything else cites it"), and catalogue order is the rule-2
  // tie-break, so the position is load-bearing.
  final areas = <Map<String, dynamic>>[kMemberKindArea];
  for (final part in parts) {
    if (part.code == kMemberKindArea['code'] ||
        part.kind == kMemberKindArea['part']) {
      throw AreasCatalogException(
          '§4.1 row ${part.code} collides with the member-kind extract home '
          '${kMemberKindArea['code']} — the registry key and kind value must '
          'stay unique.');
    }
    final code = part.code;
    final steps = areaSteps[code];
    if (steps == null || steps.isEmpty) {
      throw AreasCatalogException(
          '§4.4.6 coverage names no authoring step for $code.');
    }
    final slices = <int>[];
    for (final step in steps) {
      final slice = stepSlices[step];
      if (slice == null) {
        throw AreasCatalogException(
            '§4.4.6 coverage cites step $step for $code, but the step table '
            'has no such row.');
      }
      if (!slices.contains(slice)) slices.add(slice);
    }
    slices.sort();

    areas.add({
      'code': code,
      'canonicalId': part.canonicalId,
      'part': part.kind,
      'annotations': part.annotations,
      'builtOn': part.builtOn,
      'attributeSurface': _attributeSurface(part, surfaces[code]),
      'slices': slices,
      'authoringSteps': steps,
      'active': true,
    });
  }

  _checkStepCoverage(areaSteps, stepSlices);

  return AreasCatalog(
    source: 'codespecs_mapping.md §4.1 (parts catalogue) + §4.4.3 (emission '
        'slices) + §4.4.6 (authoring order)',
    slices: [
      for (final number in sliceRows.keys.toList()..sort())
        {
          'number': number,
          'title': sliceRows[number]!.title,
          'project': sliceRows[number]!.project,
          'cites': kSliceCites[number] ?? const <int>[],
        },
    ],
    areas: areas,
  );
}

/// Reads `codespecs_mapping.md` beside [modelDoc] and writes the catalogue to
/// [outputPath], returning the text written.
String writeAreasCatalog({
  required String mappingPath,
  required String outputPath,
}) {
  final source = File(mappingPath);
  if (!source.existsSync()) {
    throw AreasCatalogException('mapping document not found: $mappingPath');
  }
  final catalog = buildAreasCatalog(source.readAsStringSync());
  final text = catalog.toJsonText();
  Directory(p.dirname(outputPath)).createSync(recursive: true);
  File(outputPath).writeAsStringSync(text);
  return text;
}

// ---------------------------------------------------------------------------
// §4.1 — the parts catalogue
// ---------------------------------------------------------------------------

class _PartRow {
  final String code;
  final String canonicalId;
  final String kind;
  final List<String> annotations;
  final String builtOn;
  const _PartRow(
      this.code, this.canonicalId, this.kind, this.annotations, this.builtOn);
}

List<_PartRow> _parsePartsCatalogue(List<String> lines) {
  final body = _tableAfter(lines, '### 4.1 ', '§4.1');
  final rows = <_PartRow>[];
  for (final cells in body) {
    if (cells.length < 5) {
      throw AreasCatalogException('§4.1 row has ${cells.length} cells: $cells');
    }
    final code = cells[0];
    if (!RegExp(r'^CE-[A-Z]+$').hasMatch(code)) {
      throw AreasCatalogException('§4.1 row key is not a CE code: $code');
    }
    rows.add(_PartRow(
      code,
      cells[1],
      _unbacktick(cells[2]),
      [
        for (final m in RegExp(r'@(Cs\w+)').allMatches(cells[3])) m.group(1)!,
      ],
      cells[4],
    ));
  }
  if (rows.length != 26) {
    throw AreasCatalogException(
        '§4.1 declares 26 active parts; parsed ${rows.length}.');
  }
  return rows;
}

// ---------------------------------------------------------------------------
// §4.4.3 — the ordered slices
// ---------------------------------------------------------------------------

class _SliceRow {
  final String title;
  final String project;
  const _SliceRow(this.title, this.project);
}

Map<int, _SliceRow> _parseSliceTable(List<String> lines) {
  final body = _tableAfter(lines, '#### 4.4.3 ', '§4.4.3');
  final rows = <int, _SliceRow>{};
  for (final cells in body) {
    if (cells.length < 4) {
      throw AreasCatalogException('§4.4.3 row has ${cells.length} cells.');
    }
    final number = int.tryParse(_unbold(cells[0]));
    if (number == null) {
      throw AreasCatalogException('§4.4.3 row number unreadable: ${cells[0]}');
    }
    rows[number] = _SliceRow(_unbold(cells[1]), _unbacktick(cells[3]));
  }
  if (rows.length != 7) {
    throw AreasCatalogException(
        '§4.4.3 declares seven slices; parsed ${rows.length}.');
  }
  return rows;
}

// ---------------------------------------------------------------------------
// §4.4.6 — the authoring order
// ---------------------------------------------------------------------------

Map<int, int> _parseStepTable(List<String> lines) {
  final body = _tableAfter(lines, '#### 4.4.6 ', '§4.4.6');
  final steps = <int, int>{};
  for (final cells in body) {
    if (cells.length < 3) {
      throw AreasCatalogException('§4.4.6 row has ${cells.length} cells.');
    }
    final step = int.tryParse(_unbold(cells[0]));
    final slice = int.tryParse(_unbold(cells[2]));
    if (step == null || slice == null) {
      throw AreasCatalogException('§4.4.6 row unreadable: $cells');
    }
    steps[step] = slice;
  }
  if (steps.length != 31) {
    throw AreasCatalogException(
        '§4.4.6 declares 31 authoring steps; parsed ${steps.length}.');
  }
  return steps;
}

/// The `codespecs_mapping.md` §4.4.6 "Coverage" paragraph — the authoritative
/// per-part step list.
///
/// The step *table* is not the source here on purpose: two of its rows name a
/// second CE code as the host they ride ("CE-LG over the CE-DB write path"),
/// and reading codes off the row text would attribute step 13 to CE-DB. The
/// coverage paragraph is the recomputation the document itself performs, and it
/// states one step list per part.
Map<String, List<int>> _parseCoverage(List<String> lines) {
  final text = _paragraphAfter(
      lines, '#### 4.4.6 ', 'Coverage — all twenty-six active parts', '§4.4.6');
  final pattern =
      RegExp(r'(CE-[A-Z]+(?:\s*/\s*CE-[A-Z]+)*)\s*\((\d+(?:,\s*\d+)*)\)');
  final out = <String, List<int>>{};
  for (final m in pattern.allMatches(text)) {
    final codes = m
        .group(1)!
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final steps = [
      for (final s in m.group(2)!.split(',')) int.parse(s.trim()),
    ]..sort();
    for (final code in codes) {
      if (out.containsKey(code)) {
        throw AreasCatalogException(
            '§4.4.6 coverage names $code twice — the paragraph is a partition.');
      }
      out[code] = steps;
    }
  }
  if (out.length != 26) {
    throw AreasCatalogException(
        '§4.4.6 coverage should place 26 parts; parsed ${out.length}.');
  }
  return out;
}

// ---------------------------------------------------------------------------
// §5 — the attribute surfaces
// ---------------------------------------------------------------------------

/// Maps each CE code to the `codespecs_mapping.md` §5.x headings that name it.
///
/// Read off the headings rather than authored, so a `codespecs_mapping.md` §5
/// restructure carries.
Map<String, List<String>> _parseAttributeSurfaces(List<String> lines) {
  final heading = RegExp(r'^#{3,4} (5(?:\.\d+)+) (.*)$');
  final code = RegExp(r'CE-[A-Z]+');
  final out = <String, List<String>>{};
  for (final line in lines) {
    final m = heading.firstMatch(line);
    if (m == null) continue;
    for (final c in code.allMatches(m.group(2)!)) {
      (out[c.group(0)!] ??= <String>[]).add('§${m.group(1)}');
    }
  }
  return out;
}

/// Where a part's spec-authorable attribute surface is stated: the
/// `codespecs_mapping.md` §5 headings that name it, plus the `§x.y` citations
/// its own `codespecs_mapping.md` §4.1 row carries.
///
/// All section numbers below are of `codespecs_mapping.md`. The two sources are
/// unioned rather than tried in turn because neither alone is complete. CE-ER is
/// named by the heading of §5.21 in `codespecs_mapping.md` — which states the
/// *error copy* keyed by its codes, CE-TX's surface — while its own surface is
/// the §7 of `codespecs_mapping.md` its row cites; taking only the heading would
/// send a reader to the wrong section. Conversely CE-DB's row cites nothing, and
/// §5.13 of `codespecs_mapping.md` is exactly right. Falls back to §5 of
/// `codespecs_mapping.md`, whose preamble table lists every part, when neither
/// yields anything.
String _attributeSurface(_PartRow part, List<String>? headings) {
  final cited = <String>[...?headings];
  for (final m in RegExp(r'§\d+(?:\.\d+)*').allMatches(part.builtOn)) {
    final s = m.group(0)!;
    if (!cited.contains(s)) cited.add(s);
  }
  return cited.isEmpty ? '§5' : cited.join(', ');
}

// ---------------------------------------------------------------------------
// Structural checks
// ---------------------------------------------------------------------------

/// Guards [kSliceCites] without re-reading the prose that states it.
///
/// Two properties make a transcription slip visible: every edge must point
/// **strictly backwards** (`codespecs_mapping.md` §4.4.2 forbids forward
/// references outright), and the rule-1 serialisation of §4.4.6 in
/// `codespecs_mapping.md` must be a topological order of the relation — which is
/// exactly the claim that section makes about it.
void _checkCites(List<int> declaredSlices) {
  for (final slice in declaredSlices) {
    final cites = kSliceCites[slice];
    if (cites == null) {
      throw AreasCatalogException('kSliceCites has no entry for slice $slice.');
    }
    for (final cited in cites) {
      if (cited >= slice) {
        throw AreasCatalogException(
            'slice $slice cites $cited — §4.4.2 forbids forward references.');
      }
    }
  }
  final authored = <int>{};
  for (final slice in kAuthoringSliceOrder) {
    for (final cited in kSliceCites[slice] ?? const <int>[]) {
      if (!authored.contains(cited)) {
        throw AreasCatalogException(
            'the §4.4.6 serialisation ${kAuthoringSliceOrder.join(", ")} '
            'authors slice $slice before slice $cited, which it cites.');
      }
    }
    authored.add(slice);
  }
  if (authored.length != declaredSlices.length) {
    throw AreasCatalogException(
        'kAuthoringSliceOrder covers ${authored.length} of '
        '${declaredSlices.length} slices.');
  }
}

/// Every authoring step must be claimed by exactly one home — a step no area
/// names is a step no extract would ever be written for.
///
/// The `codespecs_mapping.md` §4.4.6 coverage paragraph partitions the steps
/// over the 26 parts and leaves the member-kind step(s) out (it says so: "plus
/// step 1's `domainEnum`, which is a member kind and not a part").
/// [kMemberKindArea] claims those, so the structural guard on that
/// transcription is exact-set equality: the steps it claims must be
/// **precisely** the steps the partition leaves unclaimed. A future change to
/// `codespecs_mapping.md` §4.4.6 that hands step 1 to a part, or adds a second
/// member-kind step, fails here rather than silently dropping an extract.
void _checkStepCoverage(
    Map<String, List<int>> areaSteps, Map<int, int> stepSlices) {
  final claimed = <int>{for (final steps in areaSteps.values) ...steps};
  final unclaimed = stepSlices.keys.where((s) => !claimed.contains(s)).toList()
    ..sort();
  final memberKindSteps = [...kMemberKindArea['authoringSteps'] as List]..sort();
  if (unclaimed.toString() != memberKindSteps.toString()) {
    throw AreasCatalogException(
        'the member-kind extract home ${kMemberKindArea['code']} claims steps '
        '${memberKindSteps.join(", ")}, but the §4.4.6 coverage partition '
        'leaves ${unclaimed.isEmpty ? "none" : unclaimed.join(", ")} '
        'unclaimed — the two must be the same set.');
  }
  final memberKindSlices = {
    for (final step in memberKindSteps) stepSlices[step as int]!,
  }.toList()
    ..sort();
  final declaredSlices = [...kMemberKindArea['slices'] as List]..sort();
  if (memberKindSlices.toString() != declaredSlices.toString()) {
    throw AreasCatalogException(
        'the member-kind extract home ${kMemberKindArea['code']} declares '
        'slices ${declaredSlices.join(", ")}, but its steps sit in slices '
        '${memberKindSlices.join(", ")} per the §4.4.6 step table.');
  }
}

// ---------------------------------------------------------------------------
// Markdown helpers
// ---------------------------------------------------------------------------

/// The body rows of the first pipe table after the heading starting with
/// [headingPrefix], as trimmed cell lists.
List<List<String>> _tableAfter(
    List<String> lines, String headingPrefix, String label) {
  final start = lines.indexWhere((l) => l.startsWith(headingPrefix));
  if (start < 0) {
    throw AreasCatalogException('$label heading not found.');
  }
  var i = start + 1;
  while (i < lines.length && !_isTableRow(lines[i])) {
    if (lines[i].startsWith('#')) {
      throw AreasCatalogException('$label has no table before the next heading.');
    }
    i++;
  }
  if (i >= lines.length) throw AreasCatalogException('$label has no table.');
  // Header row, then the `|---|` separator, then the body.
  i += 2;
  final rows = <List<String>>[];
  for (; i < lines.length && _isTableRow(lines[i]); i++) {
    rows.add(_cells(lines[i]));
  }
  if (rows.isEmpty) throw AreasCatalogException('$label table has no rows.');
  return rows;
}

/// The paragraph after [headingPrefix] whose first line contains [marker],
/// joined into one line so a sentence broken across lines still matches.
String _paragraphAfter(List<String> lines, String headingPrefix, String marker,
    String label) {
  final start = lines.indexWhere((l) => l.startsWith(headingPrefix));
  if (start < 0) throw AreasCatalogException('$label heading not found.');
  final begin = lines.indexWhere((l) => l.contains(marker), start);
  if (begin < 0) {
    throw AreasCatalogException('$label has no paragraph containing "$marker".');
  }
  final buffer = StringBuffer();
  for (var i = begin; i < lines.length && lines[i].trim().isNotEmpty; i++) {
    buffer.write('${lines[i]} ');
  }
  return buffer.toString();
}

bool _isTableRow(String line) => line.trimLeft().startsWith('|');

List<String> _cells(String line) {
  var text = line.trim();
  if (text.startsWith('|')) text = text.substring(1);
  if (text.endsWith('|')) text = text.substring(0, text.length - 1);
  return [for (final cell in text.split(' | ')) cell.trim()];
}

String _unbold(String cell) =>
    cell.replaceAll('**', '').replaceAll('*', '').trim();

String _unbacktick(String cell) => cell.replaceAll('`', '').trim();
