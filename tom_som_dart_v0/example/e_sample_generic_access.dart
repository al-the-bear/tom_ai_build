// Sample (e) — GENERIC / string-path access over the shared sample document.
//
// Reads the same shared sample as `d_sample_typed_access.dart`, but through the
// generic `SpecDocument` API only: every value is addressed by its section
// path, with no dependency on the generated `tom_som_dart_v0` facade. This is
// the access path a language runtime uses before (or without) a typed facade —
// e.g. a generic editor or a cross-version reader. The output matches the typed
// example exactly.
//
// Run from this package:  dart run example/e_sample_generic_access.dart
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  final sampleFile = File.fromUri(Platform.script.resolve(
      '../../tom_som_conformance/samples/meridian_order_management.docspecs.yaml'));
  final decoded = SpecDocumentYaml.decode(sampleFile.readAsStringSync());
  final doc = SpecDocument()..loadJson(decoded.document);

  stdout.writeln('=== Generic access: Meridian Order Management (SBP) ===\n');

  // Each value is fetched by its raw section path. The paths are the same ones
  // the typed getters resolve to internally.
  stdout.writeln('Blueprint summary:');
  stdout.writeln(_wrap(doc.content('SBP/content') ?? ''));
  stdout.writeln();

  stdout.writeln('Scope (SBP.2):');
  stdout.writeln(_wrap(doc.content('SBP/introductionAndScope/content') ?? ''));
  stdout.writeln();

  stdout.writeln('Goals (SBP.2 › goals):');
  stdout.writeln(
      _wrap(doc.content('SBP/introductionAndScope/goals/content') ?? ''));
  stdout.writeln();

  stdout.writeln('Target operating model (SBP.7):');
  stdout.writeln(
      _wrap(doc.content('SBP/targetOperatingModelConcept/content') ?? ''));
  stdout.writeln();

  // A list is addressed by its container path; enumerate its element paths and
  // read the `content` leaf under each.
  const metricsList = 'SBP/currentLandscape/CUOPME-OPER-LST';
  final itemPaths = doc.listItems(metricsList);
  stdout.writeln(
      'Current operational metrics (SBP.5 › ${itemPaths.length} items):');
  for (var i = 0; i < itemPaths.length; i++) {
    stdout.writeln('  ${i + 1}. ${doc.content('${itemPaths[i]}/content')}');
  }
  stdout.writeln();

  stdout.writeln('Requirements (SBP.9):');
  stdout.writeln(_wrap(doc.content('SBP/requirements/content') ?? ''));
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
