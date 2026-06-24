import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 10 (`d4rt_and_llm_tools_plan.md`) / §9.1 — the **pure** half of the
/// section-level RAG store: building the node/edge graph **from a document**
/// with zero I/O and zero model (LLM) calls.
///
/// Chunk = section (one section-id path = one node); payload = rendered text +
/// structural metadata; edges mirror the tree (`part_of`) plus the
/// `@MapsTo`/`@DetailedIn` projections (`mentions`). This file proves the graph
/// builds correctly and deterministically; the in-process persist+recall half
/// is covered by `spec_rag_store_test.dart` (which needs the bundled vec0
/// binary).
SpecModel _model() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition', 'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS', 'doc': 'Why the system exists.'},
            {'name': 'summary', 'kind': 'content', 'sectionId': 'SUM'},
            {'name': 'situation', 'kind': 'complex', 'sectionId': 'SIT', 'type': 'CurrentSituation'},
            {'name': 'risks', 'kind': 'list', 'sectionId': 'RSK', 'elementType': 'Risk', 'elementIsComplex': true},
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'mapsTo': 'PD00',
          'fields': [
            {'name': 'detail', 'kind': 'content', 'sectionId': 'DET'},
          ],
        },
        'Risk': {
          'name': 'Risk',
          'sectionId': 'RISK',
          'fields': [
            {'name': 'title', 'kind': 'content', 'sectionId': 'TIT'},
          ],
        },
      },
    });

void main() {
  late SpecModel model;
  late SpecDocument doc;
  late SpecQueryEngine engine;

  setUp(() {
    model = _model();
    doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'a platform overview');
    doc.setContent('PD00/SIT/DET', 'current platform situation');
    engine = SpecQueryEngine(model: model, document: doc);
  });

  SpecRagGraph build() => SpecRagGraph.fromProjections(engine.projectNodes());

  SpecRagNode nodeAt(SpecRagGraph g, String path) =>
      g.nodes.firstWhere((n) => n.path == path);

  bool hasEdge(SpecRagGraph g, String from, String to, SpecRagEdgeKind kind) =>
      g.edges.any((e) => e.fromPath == from && e.toPath == to && e.kind == kind);

  group('node building', () {
    test('a node is built for every projected section path', () {
      final g = build();
      final projected = {for (final p in engine.projectNodes()) p.path};
      final built = {for (final n in g.nodes) n.path};
      expect(built, projected);
    });

    test('a node carries its section facets and rendered text', () {
      final g = build();
      final vis = nodeAt(g, 'PD00/VIS');
      expect(vis.sectionId, 'VIS');
      expect(vis.kind, SpecNodeKind.content);
      // The rendered text carries the content so it is recallable.
      expect(vis.text, contains('resilient rollout platform'));
      // Structural metadata is rendered into the node text.
      expect(vis.text, contains('PD00/VIS'));
    });

    test('the root node has no parent path', () {
      final g = build();
      expect(nodeAt(g, 'PD00').parentPath, isNull);
    });

    test('a child node names its structural parent', () {
      final g = build();
      expect(nodeAt(g, 'PD00/SIT/DET').parentPath, 'PD00/SIT');
      expect(nodeAt(g, 'PD00/VIS').parentPath, 'PD00');
    });
  });

  group('tree edges (part_of)', () {
    test('every non-root node has one tree edge to its parent', () {
      final g = build();
      for (final node in g.nodes) {
        if (node.parentPath == null) continue;
        expect(
          hasEdge(g, node.path, node.parentPath!, SpecRagEdgeKind.tree),
          isTrue,
          reason: 'missing tree edge ${node.path} -> ${node.parentPath}',
        );
      }
    });

    test('the root emits no tree edge', () {
      final g = build();
      expect(g.edges.any((e) => e.fromPath == 'PD00' && e.kind == SpecRagEdgeKind.tree),
          isFalse);
    });

    test('a list item links to its container, not its grandparent', () {
      final item = doc.addListItem('PD00/RSK');
      doc.setContent('$item/TIT', 'vendor lockin');
      final g = build();
      expect(nodeAt(g, item).parentPath, 'PD00/RSK');
      expect(hasEdge(g, item, 'PD00/RSK', SpecRagEdgeKind.tree), isTrue);
      expect(hasEdge(g, '$item/TIT', item, SpecRagEdgeKind.tree), isTrue);
    });
  });

  group('projection edges (mentions)', () {
    test('a @MapsTo class projects a mentions edge to the resolved section', () {
      // CurrentSituation (the class at PD00/SIT) carries @MapsTo('PD00');
      // PD00 is the root node, so the projection resolves to a mentions edge.
      final g = build();
      expect(hasEdge(g, 'PD00/SIT', 'PD00', SpecRagEdgeKind.mapsTo), isTrue);
    });

    test('an unresolvable projection target emits no edge', () {
      // No node carries sectionId 'ZZZ', so nothing links there.
      final g = build();
      expect(g.edges.any((e) => e.toPath == 'ZZZ'), isFalse);
    });
  });
}
