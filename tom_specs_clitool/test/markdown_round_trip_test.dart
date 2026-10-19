// The markdown codec round-trips whole documents exactly (SOM §11.6, §11.7):
// parsing a document's own rendition stages every value at the path it came
// from, so `fromMarkdown(toMarkdown(doc))` equals `doc` through `toJson`.
//
// The corpus pins each rule on a small fixture; this holds the rules to real
// documents, where they meet in combinations no fixture lists. MRT-1 covers the
// shared samples, MRT-2 the tom_uam Solution Blueprint (about 10,000 values),
// which first showed the losses — skipped, with the reason, when that checkout
// is not beside this one.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

final _aiBuild = p.normalize(p.join(Directory.current.path, '..'));

SpecModel _model() => SpecModel.fromJson(
  jsonDecode(
        File(
          p.join(_aiBuild, 'tom_som_dart_v0', 'meta', 'spec_model.meta.json'),
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

/// Renders the document at [yamlPath] and parses the rendition back; expects
/// no rejection and the same values in every store.
void _expectRoundTrip(SpecModel model, String yamlPath) {
  final doc = SpecDocumentYaml.decode(
    File(yamlPath).readAsStringSync(),
    d00SolutionBlueprintMetaTree,
  ).document;
  final md = doc.toMarkdown(model, rootType: 'D00SolutionBlueprint');
  final back = SpecDocument.fromMarkdown(md, model);
  expect(back.result.rejections, isEmpty, reason: 'rejections');
  final want = doc.toJson();
  final got = back.document.toJson();
  for (final store in {...want.keys, ...got.keys}) {
    final w = (want[store] as Map?) ?? const {};
    final g = (got[store] as Map?) ?? const {};
    final differing = [
      for (final k in {...w.keys, ...g.keys})
        if (jsonEncode(w[k]) != jsonEncode(g[k])) k,
    ];
    expect(
      differing,
      isEmpty,
      reason:
          '$store values differ after the round trip '
          '(${differing.length}, first: ${differing.take(3).join(', ')})',
    );
  }
}

void main() {
  final model = _model();

  group('MRT-1: the shared samples round-trip through markdown', () {
    for (final rel in const [
      'tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
      'tom_som_conformance/samples/exercise_full_model.docspecs.yaml',
      'tom_som_conformance/samples/uam_access_hub.docspecs.yaml',
    ]) {
      test(
        p.basename(rel),
        () => _expectRoundTrip(model, p.join(_aiBuild, rel)),
      );
    }
  });

  final uam = p.normalize(
    p.join(
      _aiBuild,
      '..',
      '..',
      'tom_uam',
      'tom_specs',
      'phase2_solution_blueprint',
      'tom_uam.sbp.docspecs.yaml',
    ),
  );
  test(
    'MRT-2: the tom_uam Solution Blueprint round-trips through markdown',
    () => _expectRoundTrip(model, uam),
    skip: File(uam).existsSync()
        ? false
        : 'the tom_uam checkout is not beside this one ($uam)',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
