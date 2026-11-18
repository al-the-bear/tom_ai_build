/// The coverage-gap record of a CodeSpecs run —
/// `codespecs_derivation_contract.md` §2.11.
///
/// A coverage gap is a fact the specification states that CodeSpecs has no
/// place for. Stage B, the authoring steps and the mechanical pass
/// (`tomspecs :codespecs-validate --record-gaps`) record each one in
/// `coverage_gaps.yaml` beside the extracts; the run stops, a review settles
/// every gap, and Phase 4 restarts. A gap settled as `leaveAsIs` stays in the
/// record and is not held against the trio by check 35.
library;

import 'package:yaml/yaml.dart';

/// The record's file name, beside the extracts.
const String kCsCoverageGapFile = 'coverage_gaps.yaml';

/// The record's `formatVersion`.
const int kCsCoverageGapFormat = 1;

/// What would give a gap's fact a place in the vocabulary.
enum CsGapNeed {
  /// An argument of an existing marker.
  markerArgument,

  /// A new marker in an existing area.
  marker,

  /// A part the catalogue lacks.
  area,

  /// Not classified yet — the mechanical pass's entries, until the review.
  unknown,
}

/// Who recorded a gap.
enum CsGapFinder {
  /// Stage B of the starting prompt (`codespecs_prompt.md` §6).
  stageB,

  /// An authoring step (`codespecs_derivation_contract.md` §2.9).
  authoring,

  /// The mechanical pass over check 35's uncited tokens.
  mechanical,
}

/// How the review settled a gap.
enum CsGapResolution {
  /// Not settled yet: the run stays interrupted.
  open,

  /// The vocabulary now holds the fact.
  added,

  /// Not a vocabulary gap: corrected where it was made.
  fixed,

  /// The fact stays out of the code, knowingly.
  leaveAsIs,
}

/// A record that does not read as one.
class CsCoverageGapException implements Exception {
  /// What is wrong, naming the file and the entry.
  final String message;

  /// Creates the exception.
  const CsCoverageGapException(this.message);

  @override
  String toString() => message;
}

/// One recorded gap.
class CsCoverageGap {
  /// `GAP-<n>`, never reused.
  final String id;

  /// The extract entry's token.
  final String sectionId;

  /// The extract entry's document path.
  final String path;

  /// The entry's form field, or null when the value is the section's content.
  final String? field;

  /// The value's kind as the model declares it; null on a mechanical entry.
  final String? valueKind;

  /// The `CE-*` area the extract routed the fact to.
  final String area;

  /// What would give it a place.
  final CsGapNeed needs;

  /// Who recorded it.
  final CsGapFinder foundBy;

  /// The authoring step that recorded it, when [foundBy] is authoring.
  final int? step;

  /// One sentence on what is missing.
  final String note;

  /// How the review settled it.
  final CsGapResolution resolution;

  /// For [CsGapResolution.added]: the work that added the place.
  final String? todo;

  /// For [CsGapResolution.leaveAsIs]: why the fact stays out of the code.
  final String? reason;

  /// Creates a gap.
  const CsCoverageGap({
    required this.id,
    required this.sectionId,
    required this.path,
    required this.area,
    required this.needs,
    required this.foundBy,
    required this.note,
    this.field,
    this.valueKind,
    this.step,
    this.resolution = CsGapResolution.open,
    this.todo,
    this.reason,
  });

  /// Whether this gap names [sectionId] for [area].
  bool names(String sectionId, String area) =>
      this.sectionId == sectionId && this.area == area;
}

/// The whole record.
class CsCoverageGapRecord {
  /// The gaps, in the order they were recorded.
  final List<CsCoverageGap> gaps;

  /// Creates a record.
  const CsCoverageGapRecord(this.gaps);

  /// A record with no gaps — what a run starts from when there is no file.
  static const CsCoverageGapRecord empty = CsCoverageGapRecord([]);

  /// The gaps the review has not settled.
  Iterable<CsCoverageGap> get open =>
      gaps.where((g) => g.resolution == CsGapResolution.open);

  /// The gaps settled as left out of the code.
  Iterable<CsCoverageGap> get leftAsIs =>
      gaps.where((g) => g.resolution == CsGapResolution.leaveAsIs);

  /// Whether a `leaveAsIs` gap names [sectionId] for [area] — check 35 does
  /// not hold the trio to such a token.
  bool isLeftAsIs(String sectionId, String area) =>
      leftAsIs.any((g) => g.names(sectionId, area));

  /// Whether a finder must record nothing for [sectionId] in [area]: an
  /// `open` or `leaveAsIs` gap already names it.
  bool alreadyRecorded(String sectionId, String area) => gaps.any(
    (g) =>
        g.names(sectionId, area) &&
        (g.resolution == CsGapResolution.open ||
            g.resolution == CsGapResolution.leaveAsIs),
  );

  /// The next free `GAP-<n>` number.
  int get nextNumber {
    var max = 0;
    for (final g in gaps) {
      final n = int.tryParse(g.id.substring(4)) ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  /// This record with [gap] appended.
  CsCoverageGapRecord adding(CsCoverageGap gap) =>
      CsCoverageGapRecord([...gaps, gap]);
}

final RegExp _gapId = RegExp(r'^GAP-[1-9][0-9]*$');

/// Reads `coverage_gaps.yaml`; [source] names the file in messages.
///
/// Refuses what no finder may write: a missing required key, an unknown
/// `needs` / `foundBy` / `resolution` word, an id that is not `GAP-<n>` or is
/// there twice, `step` on a gap no authoring step found, an `added` gap
/// without `todo`, and a `leaveAsIs` gap without `reason`.
CsCoverageGapRecord readCsCoverageGaps(String text, {String source = ''}) {
  final where = source.isEmpty ? kCsCoverageGapFile : source;
  Never refuse(String what) => throw CsCoverageGapException('$where: $what');
  final Object? doc;
  try {
    doc = loadYaml(text);
  } on YamlException catch (e) {
    refuse('not YAML: ${e.message}');
  }
  if (doc is! YamlMap || doc['coverageGaps'] is! YamlMap) {
    refuse('no `coverageGaps:` map at the top');
  }
  final root = doc['coverageGaps'] as YamlMap;
  if (root['formatVersion'] != kCsCoverageGapFormat) {
    refuse(
      'formatVersion ${root['formatVersion']} is not $kCsCoverageGapFormat',
    );
  }
  final raw = root['gaps'];
  if (raw == null) return CsCoverageGapRecord.empty;
  if (raw is! YamlList) refuse('`gaps:` is not a list');
  final seen = <String>{};
  final gaps = <CsCoverageGap>[];
  for (final item in raw) {
    if (item is! YamlMap) refuse('a gap is not a map');
    String req(String key) {
      final v = item[key];
      if (v == null || '$v'.trim().isEmpty) {
        refuse('${item['id'] ?? 'a gap'} has no `$key`');
      }
      return '$v';
    }

    String? opt(String key) => item[key] == null ? null : '${item[key]}';
    T word<T extends Enum>(String key, List<T> values, {T? absent}) {
      final v = item[key];
      if (v == null && absent != null) return absent;
      for (final x in values) {
        if (x.name == v) return x;
      }
      refuse(
        '${item['id']}: `$key: $v` is none of '
        '${values.map((x) => x.name).join(', ')}',
      );
    }

    final id = req('id');
    if (!_gapId.hasMatch(id)) refuse('`$id` is not GAP-<n>');
    if (!seen.add(id)) refuse('$id is there twice');
    final foundBy = word('foundBy', CsGapFinder.values);
    final step = item['step'];
    if (step != null && (step is! int || foundBy != CsGapFinder.authoring)) {
      refuse('$id: `step` belongs to a gap an authoring step found');
    }
    final resolution = word(
      'resolution',
      CsGapResolution.values,
      absent: CsGapResolution.open,
    );
    final gap = CsCoverageGap(
      id: id,
      sectionId: req('sectionId'),
      path: req('path'),
      field: opt('field'),
      valueKind: opt('valueKind'),
      area: req('area'),
      needs: word('needs', CsGapNeed.values),
      foundBy: foundBy,
      step: step as int?,
      note: req('note'),
      resolution: resolution,
      todo: opt('todo'),
      reason: opt('reason'),
    );
    if (resolution == CsGapResolution.added && gap.todo == null) {
      refuse('$id is `added` and names no `todo`');
    }
    if (resolution == CsGapResolution.leaveAsIs && gap.reason == null) {
      refuse('$id is `leaveAsIs` and gives no `reason`');
    }
    gaps.add(gap);
  }
  return CsCoverageGapRecord(List.unmodifiable(gaps));
}

String _q(String s) =>
    '"${s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n')}"';

/// Writes [record] in the shape [readCsCoverageGaps] reads, keys in the
/// contract's order, absent keys left out.
String writeCsCoverageGaps(CsCoverageGapRecord record) {
  final b = StringBuffer()
    ..writeln('coverageGaps:')
    ..writeln('  formatVersion: $kCsCoverageGapFormat');
  if (record.gaps.isEmpty) {
    b.writeln('  gaps: []');
    return b.toString();
  }
  b.writeln('  gaps:');
  for (final g in record.gaps) {
    b
      ..writeln('    - id: ${g.id}')
      ..writeln('      sectionId: ${_q(g.sectionId)}')
      ..writeln('      path: ${_q(g.path)}');
    if (g.field != null) b.writeln('      field: ${_q(g.field!)}');
    if (g.valueKind != null) b.writeln('      valueKind: ${g.valueKind}');
    b
      ..writeln('      area: ${g.area}')
      ..writeln('      needs: ${g.needs.name}')
      ..writeln('      foundBy: ${g.foundBy.name}');
    if (g.step != null) b.writeln('      step: ${g.step}');
    b
      ..writeln('      note: ${_q(g.note)}')
      ..writeln('      resolution: ${g.resolution.name}');
    if (g.todo != null) b.writeln('      todo: ${_q(g.todo!)}');
    if (g.reason != null) b.writeln('      reason: ${_q(g.reason!)}');
  }
  return b.toString();
}
