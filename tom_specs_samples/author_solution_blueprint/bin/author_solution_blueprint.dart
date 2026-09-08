// TomSpecs sample — author a Solution Blueprint end to end.
//
// Run:  dart pub get && dart run
//
// Six steps, in the order a real authoring task takes them:
//
//   1. open a fresh document and a typed root
//   2. author a small but coherent Solution Blueprint
//   3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
//   4. round-trip the yaml back through the one-call typed loader and prove
//      the reload is equal to what was written
//   5. validate on the instance tier
//   6. break one rule deliberately and read the diagnostic
//
// This sample is the NARRATIVE. The individual access styles each have their
// own focused example in the facade package — typed, generic, reflective and
// hybrid — and this does not re-explain them:
// https://pub.dev/packages/tom_som_dart_v0/example
library;

import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

Future<void> main() async {
  final outDir = Directory('build')..createSync(recursive: true);

  // ---------------------------------------------------------------- step 1
  // A typed root over a fresh, empty document. Constructing the root also runs
  // the instantiation-time model-version check (SOM §4.2): an unstamped
  // document is editable, a document from a newer model is refused.
  final doc = SpecDocument();
  final sbp = D00SolutionBlueprint(doc);

  print('1. A typed root over an empty document');
  print('   object model version : ${sbp.objectModelVersion}');
  print('   root path            : ${sbp.path}');
  print('');

  // ---------------------------------------------------------------- step 2
  // Author. Every write below goes through a NAMED accessor — no string paths
  // — and lands in the same path-keyed store the generic API reads.
  print('2. Authoring, printing each section id as it is written');

  sbp.content = 'Unify three legacy order systems behind one customer record.';
  _wrote(sbp.path, 'the blueprint itself');

  final intro = sbp.introductionAndScope;
  intro.content = 'Replace per-region order intake with a single pipeline.';
  _wrote(intro.path, 'introduction and scope');

  final landscape = sbp.currentLandscape;
  landscape.content =
      'Three systems, no shared customer record, manual reconciliation.';
  _wrote(landscape.path, 'the current landscape');

  // A list section. `add()` appends an item and returns it typed.
  final metrics = landscape.operationalMetrics;
  metrics.add().content = 'Average order turnaround: 4.2 days.';
  metrics.add().content = 'Manual reconciliation: about 12 hours a week.';
  _wrote(metrics.listPath, '${metrics.length} operational metrics');

  print('');

  // ---------------------------------------------------------------- step 3
  // Both renditions of the same document. They are two encodings of one
  // store, not two documents — which is why step 4 can round-trip either.
  //
  // `toMarkdown` and the validator both need a whole SpecModel. The facade
  // ships one as a single expression — `somSpecModel`, in a library the barrel
  // deliberately does not export, so a consumer that never reads the model does
  // not pay for the embedded payload (SOM §10.3).
  final model = somSpecModel;

  final yaml = SpecDocumentYaml.encode(
    document: doc,
    tree: d00SolutionBlueprintMetaTree,
    modelVersion: model.modelVersionString,
  );
  final markdown = doc.toMarkdown(model, rootType: 'D00SolutionBlueprint');

  File('${outDir.path}/blueprint.docspecs.yaml').writeAsStringSync(yaml);
  File('${outDir.path}/blueprint.md').writeAsStringSync(markdown);

  print('3. Serialised both renditions into build/');
  print('   blueprint.docspecs.yaml : ${_lines(yaml)} lines  (SOM §12)');
  print('   blueprint.md            : ${_lines(markdown)} lines  (SOM §11)');
  print('');

  // ---------------------------------------------------------------- step 4
  // The one-call typed loader: decode, apply the document's own authoring
  // stamp, and hand back a typed root. Re-encoding the reload and comparing
  // the two strings is the actual proof — comparing field by field would only
  // prove the fields somebody thought to compare.
  final reloaded = D00SolutionBlueprint.loadFile(
    '${outDir.path}/blueprint.docspecs.yaml',
  );
  final reYaml = SpecDocumentYaml.encode(
    document: reloaded.doc,
    tree: d00SolutionBlueprintMetaTree,
    modelVersion: model.modelVersionString,
  );

  print('4. Round-tripped the yaml through D00SolutionBlueprint.loadFile');
  print('   reload equals original  : ${reYaml == yaml}');
  print(
    '   a value read back typed : '
    '"${reloaded.currentLandscape.operationalMetrics[0].content}"',
  );
  print('');

  // ---------------------------------------------------------------- step 5
  final errors = validateDocument(model, doc);
  print('5. Instance-tier validation');
  print('   violations              : ${errors.length}');
  print('');

  // ---------------------------------------------------------------- step 6
  // What a violation looks like. Writing to a path the model does not declare
  // is the clearest break to stage: the store accepts it — it is a plain
  // path-keyed map — and the validator is what notices.
  final broken = SpecDocument.fromYaml(yaml, d00SolutionBlueprintMetaTree);
  broken.setContent('SBP/noSuchSection/content', 'not part of the model');

  final brokenErrors = validateDocument(model, broken);
  print('6. The same document with one rule deliberately broken');
  print('   violations              : ${brokenErrors.length}');
  for (final e in brokenErrors) {
    print('   ${e.code.name}: ${e.path}');
    print('     ${e.message}');
  }
  print('');
  print('Done. The two renditions are in build/.');
}

/// Prints the section id a write landed under.
///
/// The ids are the document's addressing system — the same tokens appear in
/// the yaml keys and in the markdown `<!--[ID]-->` comments — so the sample
/// shows them rather than describing them.
void _wrote(String path, String what) =>
    print('   ${path.padRight(46)} ${what}');

int _lines(String s) => s.trimRight().split('\n').length;
