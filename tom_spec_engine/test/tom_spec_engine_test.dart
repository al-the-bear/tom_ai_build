import 'package:test/test.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart' show SpecDocument;
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart' show D00SolutionBlueprint;
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Phase-A scaffold smoke tests: the package builds and every named dependency
/// resolves and is reachable. Behavioural tests for the scope host, search,
/// memory, and agent substrate arrive with their respective plan steps.
void main() {
  group('tom_spec_engine scaffold smoke', () {
    test('package metadata is present and self-consistent', () {
      expect(tomSpecEngineName, 'tom_spec_engine');
      expect(tomSpecEngineVersion, isNotEmpty);
    });

    test('tom_d4rt interpreter dependency resolves and executes a script', () {
      // Proves the D4rt host the engine is built around is wired in.
      final result = D4rt().execute(source: 'main() => 21 + 21;');
      expect(result, 42);
    });

    test('tom_som runtime + typed v0 facade dependencies link', () {
      // Referencing one type from each proves the path dependencies resolve and
      // the generic runtime / generated facade are importable from the engine.
      expect(SpecDocument, isNotNull);
      expect(D00SolutionBlueprint, isNotNull);
    });
  });
}
