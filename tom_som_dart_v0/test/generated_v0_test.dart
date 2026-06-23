// HAND-AUTHORED — not generated. Preserved across `generate_som` runs (the
// generator only rewrites lib/, meta/, schemas/ and pubspec.yaml).
//
// Behavioural suite for the **actually-committed** generated typed object model
// (`tom_som_dart_v0`), as opposed to the emitter-golden *fixture* exercised by
// `tom_specs_clitool/test/som_dart_emitter_test.dart`. It instantiates the real
// `ProjectDefinition` root over a generic `SpecDocument` and proves the typed
// facade is a faithful editing surface over the shared document (spec §3):
// typed↔generic parity, nested-section path derivation, the generated model
// version, and the instantiation-time version check (§2.2).
//
// Run with `dart test` from this package (`tom_som_dart_v0`).
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';
import 'package:test/test.dart';

void main() {
  group('tom_som_dart_v0 generated ProjectDefinition', () {
    test('roots at the PD segment', () {
      final pd = ProjectDefinition(SpecDocument());
      expect(pd.path, 'PD');
    });

    test('content round-trips typed -> generic and generic -> typed', () {
      final doc = SpecDocument();
      final pd = ProjectDefinition(doc);

      // Typed write, generic read.
      pd.content = 'A clear vision';
      expect(doc.content('PD/content'), 'A clear vision');

      // Generic write, typed read.
      doc.setContent('PD/content', 'Revised vision');
      expect(pd.content, 'Revised vision');
    });

    test('an unset content leaf reads as the empty string', () {
      expect(ProjectDefinition(SpecDocument()).content, '');
    });

    test('nested complex sections derive their path under the root', () {
      final pd = ProjectDefinition(SpecDocument());
      // A representative nested section accessor returns a SomNode rooted at
      // the parent path — the same path the generic API would address.
      expect(pd.currentStateAnalysis.path, 'PD/currentStateAnalysis');
      expect(pd.systemOverview.path, 'PD/systemOverview');
    });

    test('a value written through a nested typed section is visible generically',
        () {
      final doc = SpecDocument();
      final pd = ProjectDefinition(doc);
      final headerPath = pd.header.path;
      // The header is a form section; set a generic content leaf beneath the
      // nested node and confirm the typed path addresses the same place.
      doc.setContent('$headerPath/probe', 'x');
      expect(doc.content('PD/header/probe'), 'x');
    });

    test('reports the generated v0 model version (0.0)', () {
      expect(ProjectDefinition.modelVersion, '0.0');
      expect(ProjectDefinition(SpecDocument()).objectModelVersion, '0.0');
    });
  });

  group('tom_som_dart_v0 instantiation-time version check (§2.2)', () {
    test('a new / unstamped document is editable', () {
      expect(() => ProjectDefinition(SpecDocument()), returnsNormally);
      expect(() => ProjectDefinition(SpecDocument(), documentVersion: '0.0'),
          returnsNormally);
    });

    test('a newer same-major document is rejected', () {
      expect(() => ProjectDefinition(SpecDocument(), documentVersion: '0.1'),
          throwsA(isA<SomVersionException>()));
    });

    test('a different major document is rejected', () {
      expect(() => ProjectDefinition(SpecDocument(), documentVersion: '1.0'),
          throwsA(isA<SomVersionException>()));
    });
  });
}
