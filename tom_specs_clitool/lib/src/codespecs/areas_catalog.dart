/// Builds the machine-readable **CodeSpecs area catalogue** — the input the
/// nine-runtime `spec_codespecs_extract` surface reads — by transcribing
/// `codespecs_mapping.md` §4.1, §4.4.3 and §4.4.6.
///
/// The catalogue is *derived*, never authored: §4.1 is the document that
/// declares itself authoritative ("the `CodeSpecPart` enum is generated from
/// this table"), so a second hand-kept copy of those 26 rows would be a second
/// thing to keep current — and the one failure mode this quest has met three
/// times is a vocabulary duplicated N ways that is wrong in agreement. Every
/// cell this builder emits is copied out of the document character for
/// character; the only judgement it makes is which cell goes in which slot.
///
/// The one thing it cannot read off a table is the across-slice **cites**
/// relation: §4.4.3 states it in the prose paragraph "Why this order (the
/// across-slice edges it satisfies)", and that paragraph contains sentences a
/// regex reads backwards ("5 cites 1 and 2 **and never 3 or 4**"). So the seven
/// edge lists are transcribed as [kSliceCites] and guarded *structurally*
/// instead — see [_checkCites].
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// The §4.4.3 across-slice edges, transcribed from the "Why this order" prose.
///
/// Not parsed, because the paragraph states one of them by negation. Guarded by
/// [_checkCites]: every edge must point strictly backwards, and the §4.4.6
/// authoring serialisation must be a topological order of the relation. A
/// transcription slip that matters shows up as one of those failing.
const Map<int, List<int>> kSliceCites = {
  1: [],
  2: [1],
  3: [1, 2],
  4: [1, 2, 3],
  5: [1, 2],
  6: [1, 5],
  7: [3, 4],
};

/// The §4.4.6 rule-1 slice serialisation. Used only as a check on [kSliceCites].
const List<int> kAuthoringSliceOrder = [1, 2, 3, 4, 7, 5, 6];

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

  /// The §4.4.3 slices, in emission order.
  final List<Map<String, dynamic>> slices;

  /// The §4.1 areas, in catalogue order. Catalogue order is §4.4.6 rule 2's
  /// tie-break, so it is load-bearing rather than cosmetic.
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

  final areas = <Map<String, dynamic>>[];
  for (final part in parts) {
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

/// The §4.4.6 "Coverage" paragraph — the authoritative per-part step list.
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

/// Maps each CE code to the `§5.x` headings that name it.
///
/// Read off the headings rather than authored, so a §5 restructure carries.
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

/// Where a part's spec-authorable attribute surface is stated: the §5 headings
/// that name it, plus the `§x.y` citations its own §4.1 row carries.
///
/// The two are unioned rather than tried in turn because neither alone is
/// complete. CE-ER is named by §5.21's heading — which states the *error copy*
/// keyed by its codes, CE-TX's surface — while its own surface is the §7 its
/// row cites; taking only the heading would send a reader to the wrong section.
/// Conversely CE-DB's row cites nothing, and §5.13 is exactly right. Falls back
/// to §5, whose preamble table lists every part, when neither yields anything.
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
/// **strictly backwards** (§4.4.2 forbids forward references outright), and the
/// §4.4.6 rule-1 serialisation must be a topological order of the relation —
/// which is exactly the claim §4.4.6 makes about it.
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

/// Every authoring step must be claimed by at least one part — a step no part
/// names is a step no extract would ever be written for.
void _checkStepCoverage(
    Map<String, List<int>> areaSteps, Map<int, int> stepSlices) {
  final claimed = <int>{for (final steps in areaSteps.values) ...steps};
  final unclaimed = stepSlices.keys.where((s) => !claimed.contains(s)).toList()
    ..sort();
  // Step 1 is the `domainEnum` member kind, which §4.1 rules is not a part —
  // so it is legitimately unclaimed, and the only one that may be.
  if (unclaimed.length != 1 || unclaimed.first != 1) {
    throw AreasCatalogException(
        'authoring steps claimed by no part: ${unclaimed.join(", ")} — only '
        'step 1 (domainEnum, a member kind rather than a part) may be.');
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
