// Sample (f) — HYBRID access: the typed→path bridge over the shared document.
//
// Reads the same shared sample as (d) and (e) and prints identical output, but
// addresses sections through the *bridge* between the two access paths (spec
// § "Expose the typed→path bridge"). Generic code that must stay dynamic — an
// editor, a cross-version reader, a batch walker — should never hard-code raw
// path literals like `'SBP/currentLandscape/CUOPME-OPER-LST'`; they are
// undiscoverable and typo-prone. There are two safe ways to obtain a path:
//
//   1. GENERATED PATH CONSTANTS. Every document root gets a `<Root>Paths`
//      holder (`SbpPaths`) of named constants whose values are the exact
//      section paths. Referencing `SbpPaths.currentLandscapeOperationalMetrics`
//      is checked by the compiler and survives model renames (the constant is
//      regenerated), while the string literal silently rots.
//
//   2. NAVIGATE-THEN-READ. Walk to a node with the typed facade and read its
//      `.path` (or a list's `.listPath`); then read/write generically off that
//      path. This is the way to build a *dynamic* path — one whose prefix comes
//      from typed navigation and whose tail is computed at runtime.
//
// Both keep raw strings out of consumer code while leaving the generic API in
// charge of the actual read/write. Contrast (d) (fully typed) and (e) (fully
// generic, raw literals).
//
// Run from this package:  dart run example/f_sample_hybrid_access.dart
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

void main() {
  final sampleFile = File.fromUri(Platform.script.resolve(
      '../../tom_som_conformance/samples/meridian_order_management.docspecs.yaml'));
  final decoded = SpecDocumentYaml.decode(sampleFile.readAsStringSync());
  final doc = SpecDocument()..loadJson(decoded.document);

  stdout.writeln('=== Hybrid access: Meridian Order Management (SBP) ===\n');

  // --- Pattern 1: generated path constants -------------------------------
  // Generic reads, but every path is a named constant instead of a literal.
  stdout.writeln('Blueprint summary:');
  stdout.writeln(_wrap(doc.content(SbpPaths.content) ?? ''));
  stdout.writeln();

  stdout.writeln('Scope (SBP.2):');
  stdout.writeln(_wrap(doc.content(SbpPaths.introductionAndScopeContent) ?? ''));
  stdout.writeln();

  stdout.writeln('Goals (SBP.2 › goals):');
  stdout.writeln(
      _wrap(doc.content(SbpPaths.introductionAndScopeGoalsContent) ?? ''));
  stdout.writeln();

  stdout.writeln('Target operating model (SBP.7):');
  stdout.writeln(
      _wrap(doc.content(SbpPaths.targetOperatingModelConceptContent) ?? ''));
  stdout.writeln();

  // --- Pattern 2: navigate-then-read -------------------------------------
  // Navigate to the list with the typed facade, take its `.listPath`, then
  // enumerate item paths and read each `content` leaf generically. The prefix
  // is discovered by typed navigation; the per-item tail is computed at
  // runtime — exactly the case a bare path constant cannot express.
  final sbp = D00SolutionBlueprint(doc, documentVersion: decoded.modelVersion);
  final metricsPath = sbp.currentLandscape.operationalMetrics.listPath;
  final itemPaths = doc.listItems(metricsPath);
  stdout.writeln(
      'Current operational metrics (SBP.5 › ${itemPaths.length} items):');
  for (var i = 0; i < itemPaths.length; i++) {
    stdout.writeln('  ${i + 1}. ${doc.content('${itemPaths[i]}/content')}');
  }
  stdout.writeln();

  // Back to a path constant for the final leaf.
  stdout.writeln('Requirements (SBP.9):');
  stdout.writeln(_wrap(doc.content(SbpPaths.requirementsContent) ?? ''));
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
