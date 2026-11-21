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
