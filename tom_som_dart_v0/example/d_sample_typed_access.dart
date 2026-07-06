// Sample (d) — CONCRETE / typed access over the shared sample document.
//
// Loads the language-agnostic shared sample
// (`tom_som_conformance/samples/meridian_order_management.docspecs.yaml`) into a
// `SpecDocument`, then wraps it in the generated `D00SolutionBlueprint` facade
// and reads key sections through typed getters. Contrast with
// `e_sample_generic_access.dart`, which reaches the same values via raw string
// paths — the two print identical output.
//
// Run from this package:  dart run example/d_sample_typed_access.dart
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

void main() {
  // Load the shared sample from the conformance corpus, three levels up.
  final sampleFile = File.fromUri(Platform.script.resolve(
      '../../tom_som_conformance/samples/meridian_order_management.docspecs.yaml'));
  final decoded = SpecDocumentYaml.decode(sampleFile.readAsStringSync());
  final doc = SpecDocument()..loadJson(decoded.document);

  // Wrap the loaded document in the typed facade. The sample is stamped 1.0;
  // the facade verifies it is editable for its own model version.
  final sbp = D00SolutionBlueprint(doc, documentVersion: decoded.modelVersion);

  stdout.writeln('=== Typed access: Meridian Order Management (SBP) ===\n');

  // Top-level narrative — a single typed getter per section.
  stdout.writeln('Blueprint summary:');
  stdout.writeln(_wrap(sbp.content));
  stdout.writeln();

  stdout.writeln('Scope (SBP.2):');
  stdout.writeln(_wrap(sbp.introductionAndScope.content));
  stdout.writeln();

  // One level deeper — nested typed navigation reads like the domain.
  stdout.writeln('Goals (SBP.2 › goals):');
  stdout.writeln(_wrap(sbp.introductionAndScope.goals.content));
  stdout.writeln();

  stdout.writeln('Target operating model (SBP.7):');
  stdout.writeln(_wrap(sbp.targetOperatingModelConcept.content));
  stdout.writeln();

  // A typed collection — iterate the operational-metrics list off the current
  // landscape section. Each element is a typed facade with its own getters.
  final metrics = sbp.currentLandscape.operationalMetrics;
  stdout.writeln('Current operational metrics (SBP.5 › ${metrics.length} items):');
  for (var i = 0; i < metrics.length; i++) {
    stdout.writeln('  ${i + 1}. ${metrics[i].content}');
  }
  stdout.writeln();

  stdout.writeln('Requirements (SBP.9):');
  stdout.writeln(_wrap(sbp.requirements.content));
}

/// Hanging-indents a paragraph so long section bodies stay readable in a
/// terminal without altering the stored value.
String _wrap(String text, {int width = 76}) {
  final words = text.split(' ');
  final lines = <String>[];
  var line = StringBuffer('  ');
  for (final w in words) {
    if (line.length + w.length + 1 > width && line.length > 2) {
      lines.add(line.toString());
      line = StringBuffer('  ');
    }
    if (line.length > 2) line.write(' ');
    line.write(w);
  }
  if (line.length > 2) lines.add(line.toString());
  return lines.join('\n');
}
