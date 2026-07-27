import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 9 / `llm_and_d4rt_tools.md` §6 + §9.2: the **tier-1
/// structural/lexical index** — an inverted BM25 text index + structural facets
/// (id, kind, mapsTo, state) built **directly from the object model with zero
/// model (LLM) calls**, refreshed **incrementally** over changed sections.
///
/// Done-criterion: index refresh is incremental and search returns correct hits
/// with no LLM call.
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
  late StructuralLexicalIndex index;

  setUp(() {
    model = _model();
    doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform resilient');
    doc.setContent('PD00/SUM', 'a resilient platform overview');
    doc.setContent('PD00/SIT/DET', 'current platform situation');
    engine = SpecQueryEngine(model: model, document: doc);
    index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
  });

  List<String> paths(List<IndexHit> hits) => [for (final h in hits) h.path];

  group('text search (BM25, no LLM)', () {
    test('ranks a higher-term-frequency section first', () {
      final hits = index.search(const IndexQuery(text: 'resilient'));
      // Both VIS (resilient x2) and SUM (resilient x1) match; VIS ranks higher.
      expect(paths(hits), ['PD00/VIS', 'PD00/SUM']);
      expect(hits.first.score, greaterThan(hits.last.score));
    });

    test('matches multiple terms and excludes non-matching sections', () {
      final hits = index.search(const IndexQuery(text: 'situation'));
      expect(paths(hits), ['PD00/SIT/DET']);
    });

    test('a missing term returns no hits', () {
      expect(index.search(const IndexQuery(text: 'kubernetes')), isEmpty);
    });
  });

  group('structural facets', () {
    test('kind filter narrows to a node kind', () {
      final hits = index.search(const IndexQuery(kinds: {SpecNodeKind.content}));
      expect(paths(hits), containsAll(['PD00/VIS', 'PD00/SUM', 'PD00/SIT/DET']));
      expect(paths(hits), isNot(contains('PD00'))); // the root is not content
    });

    test('className filter selects nodes of a class', () {
      final hits = index.search(const IndexQuery(className: 'CurrentSituation'));
      expect(paths(hits), ['PD00/SIT']);
    });

    test('sectionId prefix filter', () {
      final hits = index.search(const IndexQuery(sectionIdPrefix: 'VIS'));
      expect(paths(hits), ['PD00/VIS']);
    });

    test('mapsTo facet', () {
      final hits = index.search(const IndexQuery(mapsTo: 'PD00'));
      expect(paths(hits), ['PD00/SIT']);
    });

    test('state facet (non-empty) excludes empty declared leaves', () {
      final hits = index.search(
          const IndexQuery(kinds: {SpecNodeKind.content}, state: IndexStateFilter.nonEmpty));
      expect(paths(hits), containsAll(['PD00/VIS', 'PD00/SUM', 'PD00/SIT/DET']));
    });

    test('text + facet are AND-combined', () {
      final hits = index.search(
          const IndexQuery(text: 'platform', sectionIdPrefix: 'SUM'));
      expect(paths(hits), ['PD00/SUM']);
    });
  });

  group('incremental refresh', () {
    test('updating one section touches only that section', () {
      expect(paths(index.search(const IndexQuery(text: 'resilient'))),
          ['PD00/VIS', 'PD00/SUM']);
      final before = index.sectionCount;

      doc.setContent('PD00/VIS', 'bar baz quux');
      final stats = index.update(changed: [engine.projectNode('PD00/VIS')!]);

      expect(stats.updated, 1);
      expect(stats.added, 0);
      expect(stats.removed, 0);
      expect(index.sectionCount, before); // no full rebuild

      // VIS no longer matches the old term; the new term hits it.
      expect(paths(index.search(const IndexQuery(text: 'resilient'))),
          ['PD00/SUM']);
      expect(paths(index.search(const IndexQuery(text: 'bar'))), ['PD00/VIS']);
      // An untouched section's postings are intact.
      expect(paths(index.search(const IndexQuery(text: 'situation'))),
          ['PD00/SIT/DET']);
    });

    test('adding then removing a list item refreshes incrementally', () {
      final item = doc.addListItem('PD00/RSK');
      doc.setContent('$item/TIT', 'vendor lockin risk');
      index.update(changed: [
        engine.projectNode(item)!,
        engine.projectNode('$item/TIT')!,
      ]);
      expect(paths(index.search(const IndexQuery(text: 'lockin'))),
          ['$item/TIT']);

      final afterAdd = index.sectionCount;
      doc.removeListItem(item);
      final stats = index.update(removed: ['$item/TIT', item]);
      expect(stats.removed, 2);
      expect(index.sectionCount, afterAdd - 2);
      expect(index.search(const IndexQuery(text: 'lockin')), isEmpty);
    });

    test('a re-projected new path is added, not updated', () {
      final item = doc.addListItem('PD00/RSK');
      final stats = index.update(changed: [engine.projectNode(item)!]);
      expect(stats.added, 1);
      expect(stats.updated, 0);
    });
  });
}
