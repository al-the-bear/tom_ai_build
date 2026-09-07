// Decode gate for every shared conformance sample.
//
// Loads every `*.docspecs.yaml` sample through the typed
// one-call loader (`D00SolutionBlueprint.loadFile`), which decodes the file
// against the SBP metadata tree — so every mapping key must match a model
// member at its position (SOM §12) and every value must have a legal shape.
// A sample that only *looks* structurally plausible fails here with a precise
// `SpecYamlFormatException` naming the offending key and path.
//
// This is deliberately the *decode* tier only. The two validation tiers
// (schema completeness + `validateDocument`, see `samples/README.md`) are
// gated per-sample by `build_shared_sample.dart` for the Meridian document;
// coverage-oriented samples (the instantiation-coverage campaign, SOM §19)
// are required to decode cleanly but not to satisfy list minima or
// `refersTo` resolution.
//
// TWO SAMPLE DIRECTORIES, and the split is deliberate. `samples/` in this
// package holds the Meridian Solution Blueprint: it is the document the
// `d_`/`e_`/`f_` examples load, so it has to *ship*, and a shipped example
// cannot read a file from an unpublished sibling. The conformance corpus at
// `../tom_som_conformance/samples/` holds the coverage-oriented fixtures,
// which nothing ships. Both are scanned here so that moving the Meridian
// document into the package did not quietly drop it from this gate.
//
//   cd tom_som_dart_v0 && dart run tool/verify_samples.dart
//
// Exit code 0 when every sample decodes; 1 otherwise.
import 'dart:io';

import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

void main() {
  final samplesDirs = [
    Directory('documents'),
    Directory('../tom_som_conformance/samples'),
  ];
  // Both must exist. Tolerating an absent one would let this gate report
  // success over half the corpus after a directory is renamed or moved.
  for (final d in samplesDirs) {
    if (!d.existsSync()) {
      stderr.writeln('samples folder missing: ${d.path}');
      exit(1);
    }
  }
  final files = [
    for (final d in samplesDirs)
      ...d
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.docspecs.yaml')),
  ]..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('no *.docspecs.yaml samples under '
        '${samplesDirs.map((d) => d.path).join(', ')}');
    exit(1);
  }
  var failures = 0;
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    try {
      final sbp = D00SolutionBlueprint.loadFile(f.path);
      final doc = sbp.doc;
      stdout.writeln('OK  $name '
          '(${doc.contentPaths.length} content, '
          '${doc.formPaths.length} forms, '
          '${doc.listPaths.length} lists)');
    } catch (e) {
      failures++;
      stderr.writeln('FAIL $name: $e');
    }
  }
  if (failures > 0) {
    stderr.writeln('FAILED: $failures sample(s) do not decode.');
    exit(1);
  }
  stdout.writeln('All ${files.length} samples decode cleanly.');
}
