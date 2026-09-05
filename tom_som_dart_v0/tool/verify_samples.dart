// Decode gate for every shared conformance sample.
//
// Loads each `tom_som_conformance/samples/*.docspecs.yaml` through the typed
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
//   cd tom_som_dart_v0 && dart run tool/verify_samples.dart
//
// Exit code 0 when every sample decodes; 1 otherwise.
import 'dart:io';

import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

void main() {
  final samplesDir = Directory('../tom_som_conformance/samples');
  if (!samplesDir.existsSync()) {
    stderr.writeln('samples folder missing: ${samplesDir.path}');
    exit(1);
  }
  final files = samplesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.docspecs.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('no *.docspecs.yaml samples under ${samplesDir.path}');
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
