// Sample (a) — TYPED object-model access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites lib/, meta/, schemas/ and pubspec.yaml; it never touches example/).
//
// Demonstrates editing a TomSpecs document through the generated *typed*
// facade `tom_som_dart_v0`: named getters/setters, nested-section navigation,
// and the typed `SomList` collection API. The typed facade is a thin editing
// surface over a generic `SpecDocument` — every typed write lands in the same
// path-keyed store the generic API (sample b) reads, which the closing lines
// prove.
//
// Run from this package:  dart run example/a_typed_access.dart
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

void main() {
  // A typed root over a fresh, empty document. The constructor also runs the
  // §2.2 instantiation-time version check (an unstamped document is editable).
  final doc = SpecDocument();
  final pd = D00SolutionBlueprint(doc);

  print('Model version of this typed facade: ${pd.objectModelVersion}');
  print('Root path: ${pd.path}\n');

  // 1) A content leaf directly on the root.
  pd.content = 'A platform that unifies our fragmented order systems.';

  // 2) Navigate into a nested complex section and edit its own content leaf —
  //    no string paths, just typed accessors.
  final csa = pd.currentLandscape;
  csa.content = 'Three legacy systems with no shared customer record.';

  // 3) The typed collection API: append two list items and edit each.
  final metrics = csa.operationalMetrics;
  metrics.add().content = 'Average order turnaround: 4.2 days.';
  metrics.add().content = 'Manual reconciliation: ~12 hours / week.';

  // Read everything back through the typed getters.
  print('SBP.content              = ${pd.content}');
  print('SBP.currentLandscape = ${csa.content}');
  print('operationalMetrics.length = ${metrics.length}');
  for (var i = 0; i < metrics.length; i++) {
    print('  metric[$i] = ${metrics[i].content}');
  }

  // The typed path is the generic path: the same data is addressable through
  // the generic document API (this is exactly what sample (b) uses).
  print('\nSame value via the generic path '
      '(doc.content("${csa.path}/content")):');
  print('  ${doc.content('${csa.path}/content')}');
}
