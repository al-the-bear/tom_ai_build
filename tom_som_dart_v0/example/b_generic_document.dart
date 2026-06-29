// Sample (b) — GENERIC in-memory document access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs.
//
// Demonstrates editing the *same* document shape as sample (a) using ONLY the
// generic `tom_som_dart_runtime` — string paths, no generated typed classes.
// This is the language-independent core: a sparse, path-keyed store plus the
// list and serialization helpers. Anything the typed facade can express is
// expressible here; the typed facade just makes it type-safe and discoverable.
//
// Run from this package:  dart run example/b_generic_document.dart
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  final doc = SpecDocument();

  // Content leaves are addressed by their full path from the root segment.
  doc.setContent('SBP/content',
      'A platform that unifies our fragmented order systems.');
  doc.setContent('SBP/currentLandscape/content',
      'Three legacy systems with no shared customer record.');

  // A list: append items (each call returns the new item's path), then set a
  // content leaf under each. The list path mirrors the typed facade's
  // `operationalMetrics` accessor.
  const listPath = 'SBP/currentLandscape/CUOPME-OPER-LST';
  final item0 = doc.addListItem(listPath);
  doc.setContent('$item0/content', 'Average order turnaround: 4.2 days.');
  final item1 = doc.addListItem(listPath);
  doc.setContent('$item1/content', 'Manual reconciliation: ~12 hours / week.');

  // Read back generically.
  print('SBP/content = ${doc.content('SBP/content')}');
  print('list item count = ${doc.listItemCount(listPath)}');
  for (final itemPath in doc.listItems(listPath)) {
    print('  $itemPath/content = ${doc.content('$itemPath/content')}');
  }

  // The whole document serializes losslessly to JSON …
  print('\nDocument JSON:');
  print(doc.toJson());

  // … and to the canonical YAML wire format (stamped with the model version).
  print('\nDocument YAML:');
  print(SpecDocumentYaml.encode(document: doc, modelVersion: '0.0'));
}
