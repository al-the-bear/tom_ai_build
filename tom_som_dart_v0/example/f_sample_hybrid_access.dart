// Sample (f) — HYBRID access: the typed→path bridge over the shared document.
//
// Reads the same shared sample as (d) and (e) and prints identical output, but
// addresses sections through the *bridge* between the two access paths (SOM
// §8). Generic code that must stay dynamic — an editor, a cross-version
// reader, a batch walker — should never hard-code raw path literals like
// `'SBP/currentLandscape/CUOPME-OPER-LST'`; they are undiscoverable and
// typo-prone. There are two safe ways to obtain a path:
//
//   1. GENERATED METADATA REFS. Every document root gets a dot-notation entry
//      point (`d00SolutionBlueprint`) whose member chain mirrors the model;
//      each position exposes `.path` (and `.meta` for the full metadata node).
//      Referencing `d00SolutionBlueprint.requirements.content.path` is checked
//      by the compiler and survives model renames (the accessor classes are
//      regenerated), while a string literal silently rots. The ID-tree entry
//      point (`SBP`) offers the same positions keyed by section id.
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
  // Load the shared sample (hierarchical v2 yaml) against the SBP metadata
  // tree via the generic one-call loader.
  final sampleFile = File.fromUri(Platform.script.resolve(
      '../../tom_som_conformance/samples/meridian_order_management.docspecs.yaml'));
  final doc =
      SpecDocument.fromFile(sampleFile.path, d00SolutionBlueprintMetaTree);

  stdout.writeln('=== Hybrid access: Meridian Order Management (SBP) ===\n');

  // --- Pattern 1: generated metadata refs ---------------------------------
  // Generic reads, but every path comes off the dot-notation metadata surface
  // instead of a literal.
  stdout.writeln('Blueprint summary:');
  stdout.writeln(_wrap(doc.content(d00SolutionBlueprint.content.path) ?? ''));
  stdout.writeln();

  stdout.writeln('Scope (SBP.2):');
  stdout.writeln(_wrap(
      doc.content(d00SolutionBlueprint.introductionAndScope.content.path) ??
          ''));
  stdout.writeln();

  stdout.writeln('Goals (SBP.2 › goals):');
  stdout.writeln(_wrap(doc.content(d00SolutionBlueprint
          .introductionAndScope.goals.content.path) ??
      ''));
  stdout.writeln();

  stdout.writeln('Target operating model (SBP.7):');
  stdout.writeln(_wrap(doc.content(
          d00SolutionBlueprint.targetOperatingModelConcept.content.path) ??
      ''));
  stdout.writeln();

  // --- Pattern 2: navigate-then-read -------------------------------------
  // Navigate to the list with the typed facade, take its `.listPath`, then
  // enumerate item paths and read each `content` leaf generically. The prefix
  // is discovered by typed navigation; the per-item tail is computed at
  // runtime — exactly the case a bare metadata ref cannot express.
  // `fromFile` retained the yaml's modelVersion stamp on the document, so the
  // facade picks it up without threading it by hand.
  final sbp = D00SolutionBlueprint(doc, documentVersion: doc.modelVersion);
  final metricsPath = sbp.currentLandscape.operationalMetrics.listPath;
  final itemPaths = doc.listItems(metricsPath);
  stdout.writeln(
      'Current operational metrics (SBP.5 › ${itemPaths.length} items):');
  for (var i = 0; i < itemPaths.length; i++) {
    stdout.writeln('  ${i + 1}. ${doc.content('${itemPaths[i]}/content')}');
  }
  stdout.writeln();

  // Back to a metadata ref for the final leaf.
  stdout.writeln('Requirements (SBP.9):');
  stdout.writeln(_wrap(
      doc.content(d00SolutionBlueprint.requirements.content.path) ?? ''));
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
