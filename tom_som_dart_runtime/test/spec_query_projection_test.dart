import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'fixture.dart';

/// The flat node projection ([SpecQueryEngine.projectNodes] /
/// [SpecQueryEngine.projectNode]) the tier-1 structural/lexical index
/// (`d4rt_and_llm_tools.md` §9.2) is built from. It must surface, per node, the
/// same structural-closure walk the live query uses plus the searchable strings
/// and structural facets, with **zero** model (LLM) calls.
void main() {
  late SpecModel model;
  late SpecDocument doc;
  late SpecQueryEngine engine;

  setUp(() {
    model = fixtureModel();
    doc = SpecDocument();
    doc.setContent('PD00/vision', 'Deliver a resilient rollout platform.');
    doc.setFormField('PD00/owner', 'name', 'Ada Lovelace');
    final risk = doc.addListItem('PD00/risks');
    doc.setContent('$risk/title', 'Vendor lock-in');
    engine = SpecQueryEngine(model: model, document: doc);
  });

  group('projectNodes', () {
    test('projects every node of the structural closure once', () {
      final byPath = {for (final p in engine.projectNodes()) p.path: p};
      // The declared leaves, containers, and the descended list item are present.
      expect(byPath, contains('PD00')); // root
      expect(byPath, contains('PD00/vision')); // content leaf
      expect(byPath, contains('PD00/owner')); // form
      expect(byPath, contains('PD00/risks')); // list container
      final itemRe = RegExp(r'^PD00/risks-\d+$');
      expect(byPath.keys.where(itemRe.hasMatch), hasLength(1)); // one item
    });

    test('carries kind, class, searchable strings and value state', () {
      final byPath = {for (final p in engine.projectNodes()) p.path: p};

      final vision = byPath['PD00/vision']!;
      expect(vision.kind, SpecNodeKind.content);
      expect(vision.searchableStrings, contains('Deliver a resilient rollout platform.'));
      expect(vision.hasValue, isTrue);

      final owner = byPath['PD00/owner']!;
      expect(owner.kind, SpecNodeKind.form);
      expect(owner.searchableStrings, contains('Ada Lovelace'));

      final riskItemPath = byPath.keys
          .firstWhere((p) => RegExp(r'^PD00/risks-\d+$').hasMatch(p));
      final riskItem = byPath[riskItemPath]!;
      expect(riskItem.kind, SpecNodeKind.listItemComplex);
      expect(riskItem.classId, 'Risk');
    });

    test('an empty declared leaf projects with hasValue=false', () {
      // CurrentSituation.summary was never set.
      final byPath = {for (final p in engine.projectNodes()) p.path: p};
      final summary = byPath['PD00/situation/summary']!;
      expect(summary.kind, SpecNodeKind.content);
      expect(summary.hasValue, isFalse);
      expect(summary.searchableStrings, isEmpty);
    });
  });

  group('projectNode', () {
    test('projects a single resolvable path', () {
      final vision = engine.projectNode('PD00/vision');
      expect(vision, isNotNull);
      expect(vision!.path, 'PD00/vision');
      expect(vision.searchableStrings, contains('Deliver a resilient rollout platform.'));
    });

    test('returns null for an unresolvable path', () {
      expect(engine.projectNode('PD00/nope'), isNull);
    });
  });
}
