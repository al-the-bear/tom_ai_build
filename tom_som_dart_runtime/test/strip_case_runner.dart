// The runners of tom_som_conformance/corpus/strip_cases.json (SOM §11.10),
// shared by the conformance test and the strip unit tests.

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

List<String> _names(Map<String, dynamic> c, String key) =>
    (c[key] as List? ?? const []).cast<String>();

/// The options a case names.
SpecStripOptions stripCaseOptions(Map<String, dynamic> c) =>
    SpecStripOptions.fromNames(
      drop: _names(c, 'drop'),
      unmark: _names(c, 'unmark'),
      appendix: _names(c, 'appendix'),
      appendixReferences: c['appendixReferences'] as bool? ?? false,
      headingDivs: c['headingDivs'] as bool? ?? false,
    );

/// [options] as the corpus writes them.
Map<String, Object?> stripOptionsJson(SpecStripOptions o) => {
  'drop': SpecStripOptions.ordered(o.drop),
  'unmark': SpecStripOptions.ordered(o.unmark),
  'appendix': SpecStripOptions.ordered(o.appendix),
  'appendixReferences': o.appendixReferences,
  'headingDivs': o.headingDivs,
};

/// [stripped] with every piece put back at its anchor: the original.
String unstrip(String stripped, List<SpecStripPiece> pieces) {
  final b = StringBuffer();
  var at = 0;
  for (final p in pieces) {
    b
      ..write(stripped.substring(at, p.anchor))
      ..write(p.removed);
    at = p.anchor + p.inserted.length;
  }
  b.write(stripped.substring(at));
  return b.toString();
}

/// A `cases` entry: the result of stripNotationText.
Map<String, Object?> runStripTextCase(Map<String, dynamic> c) =>
    stripNotationText(c['text'] as String, stripCaseOptions(c)).toJson();

/// A `usageCases` entry: the expanded options, or the usage error.
Map<String, Object?> runStripUsageCase(Map<String, dynamic> c) {
  try {
    return stripOptionsJson(stripCaseOptions(c));
  } on SpecStripUsageError catch (e) {
    return {'error': e.message};
  }
}

/// A `headerCases` entry: the parse of the line, or null.
Map<String, Object?>? runStripHeaderCase(Map<String, dynamic> c) {
  final h = SpecReadableHeader.parse(c['line'] as String);
  if (h == null) return null;
  final s = h.source;
  return {
    ...stripOptionsJson(h.options),
    if (s != null)
      'source': {
        'file': s.file,
        'revision': s.revision,
        'commit': s.commit,
        'dirty': s.dirty,
      },
    'format': h.format(),
  };
}

/// [text] with each `[find, replace]` of [edits] applied; each `find` must
/// occur exactly once (an empty `find` fills an empty text).
String applyCaseEdits(String text, List<dynamic>? edits) {
  var out = text;
  for (final e in edits ?? const []) {
    final find = (e as List)[0] as String, replace = e[1] as String;
    if (find.isEmpty) {
      if (out.isNotEmpty) throw StateError('an empty find needs an empty text');
      out = replace;
      continue;
    }
    final at = out.indexOf(find);
    if (at < 0 || out.indexOf(find, at + 1) >= 0) {
      throw StateError('the edit "$find" does not occur exactly once');
    }
    out = out.replaceRange(at, at + find.length, replace);
  }
  return out;
}

SpecReadableSource? _caseSource(Map<String, dynamic> c) {
  final src = c['source'] as Map?;
  return src == null
      ? null
      : SpecReadableSource(
          file: src['file'] as String,
          revision: src['revision'] as String?,
          commit: src['commit'] as String?,
          dirty: src['dirty'] as bool? ?? false,
        );
}

/// A `strip_merge_cases.json` `valueCases` entry: the original stripped with
/// the case's switches, the edits applied to the stripped text, and the
/// merge of that onto the original.
Map<String, Object?> runStripMergeValueCase(Map<String, dynamic> c) {
  final o = c['original'] as String;
  final s = stripNotationText(o, stripCaseOptions(c));
  final e = applyCaseEdits(s.text, c['edits'] as List?);
  return mergeStrippedValue(o, s.text, e, s.pieces).toJson();
}

/// A `strip_merge_cases.json` `documentCases` entry: `state` stripped (with
/// the case's switches and `source`) into a readable rendition, the edits
/// applied to it, and the merge of that onto `current` (else `state`); `base`
/// is given by hand and `commits` is what the header's commit loads.
/// `options` names switches given beside the header. A usage error gives
/// `{error}`.
Map<String, Object?> runStripMergeDocumentCase(
  Map<String, dynamic> c,
  SpecModel model,
  DocSpecsSchema schema,
) {
  SpecDocument doc(Object? json) => SpecDocument()..loadJson(json! as Map);
  final state = doc(c['state']);
  final readable = SpecDocumentStrip.strip(
    state,
    stripCaseOptions(c),
    model: model,
    schema: schema,
    source: _caseSource(c),
  ).readable!;
  final edited = applyCaseEdits(readable, c['edits'] as List?);
  final given = c['options'] as Map<String, dynamic>?;
  final commits = (c['commits'] as Map?) ?? const {};
  try {
    final r = SpecStripMerge.merge(
      c['current'] == null ? state : doc(c['current']),
      edited,
      model: model,
      schema: schema,
      options: given == null ? null : stripCaseOptions(given),
      currentRevision: c['currentRevision'] as String?,
      base: c['base'] == null ? null : doc(c['base']),
      loadBase: (s) =>
          commits[s.commit] == null ? null : doc(commits[s.commit]),
    );
    return {
      'exitCode': r.exitCode,
      'stale': r.stale,
      'document': r.document?.toJson(),
      'report': r.report,
    };
  } on SpecStripUsageError catch (e) {
    return {'error': e.message};
  }
}

/// A `documentCases` entry: the document strip, over [model] and [schema]
/// unless the case says `model: false`.
Map<String, Object?> runStripDocumentCase(
  Map<String, dynamic> c,
  SpecModel model,
  DocSpecsSchema schema,
) {
  final doc = SpecDocument()..loadJson(c['state'] as Map);
  final src = c['source'] as Map?;
  final withModel = c['model'] != false;
  final r = SpecDocumentStrip.strip(
    doc,
    stripCaseOptions(c),
    model: withModel ? model : null,
    schema: withModel ? schema : null,
    rootType: c['rootType'] as String?,
    source: src == null
        ? null
        : SpecReadableSource(
            file: src['file'] as String,
            revision: src['revision'] as String?,
            commit: src['commit'] as String?,
            dirty: src['dirty'] as bool? ?? false,
          ),
  );
  return {
    'document': r.document.toJson(),
    'kept': [for (final k in r.kept) k.ref.toJson()],
    'removedItems': r.removedItems,
    'appendix': [for (final e in r.appendix) e.toJson()],
    'dropped': r.dropped,
    'unmarked': r.unmarked,
    'appended': r.appended,
    'marksDropped': r.marksDropped,
    'readableHeader': r.readableHeader,
    'readable': r.readable,
    'findings': [for (final f in r.findings) f.kind],
  };
}
