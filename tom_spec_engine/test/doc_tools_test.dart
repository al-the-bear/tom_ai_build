import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// `llm_and_d4rt_tools.md` §8.2 — the in-memory **document**
/// tools: `doc_search` + `doc_search_iterate` (the §6 grep facility, cursor
/// iteration), `doc_reflect` (meta-model facts: allowed children / types /
/// annotations), and `doc_add_node` (the §5 meta-model-validated creation that
/// lands in the **one change log**).
///
/// Done-criterion: each tool returns compact JSON and the mutating tool lands in
/// the one change log.
SpecModel _model() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'ProjectDefinition', 'title': 'Project Definition', 'sectionId': 'PD00'},
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'annotations': [
            {'name': 'Document', 'arguments': {'title': 'Project Definition'}},
          ],
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS', 'doc': 'Why the system exists.'},
            {'name': 'summary', 'kind': 'content', 'sectionId': 'SUM'},
            {'name': 'situation', 'kind': 'complex', 'sectionId': 'SIT', 'type': 'CurrentSituation'},
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'RSK',
              'sectionIdPattern': r'PD00/RSK-\d+',
              'elementType': 'Risk',
              'elementIsComplex': true,
            },
          ],
        },
        'CurrentSituation': {
          'name': 'CurrentSituation',
          'sectionId': 'CS00',
          'mapsTo': 'PD00',
          'detailedIn': 'CS00',
          'doc': 'The current situation, detailed elsewhere.',
          'annotations': [
            {'name': 'MapsTo', 'arguments': {'target': 'PD00'}},
          ],
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

/// A minimal change-log entry the done-criterion compares.
class _Change {
  final String kind;
  final String path;
  const _Change(this.kind, this.path);

  @override
  bool operator ==(Object other) =>
      other is _Change && other.kind == kind && other.path == path;

  @override
  int get hashCode => Object.hash(kind, path);

  @override
  String toString() => '_Change($kind, $path)';
}

/// A faithful stand-in for the live controller: records one change-log entry per
/// effective mutation (the §5 "one change log" discipline).
class _RecordingController implements SpecController {
  _RecordingController(this.model, this.document);

  final SpecModel model;
  final SpecDocument document;
  final List<_Change> log = [];

  void _commit(SpecDocumentState before, _Change Function() entry) {
    final after = document.captureState();
    if (before.fingerprint == after.fingerprint) return;
    log.add(entry());
  }

  @override
  String? content(String path) => document.content(path);

  @override
  String? formField(String path, String field) =>
      document.formField(path, field);

  @override
  List<String> listItems(String listPath) => document.listItems(listPath);

  @override
  void setContent(String path, String value) {
    final before = document.captureState();
    document.setContent(path, value);
    _commit(before, () => _Change('content', path));
  }

  @override
  void setFormField(String path, String field, String value) {
    final before = document.captureState();
    document.setFormField(path, field, value);
    _commit(before, () => _Change('form:$field', path));
  }

  @override
  String addListItem(String listPath) {
    final before = document.captureState();
    final itemPath = document.addListItem(listPath);
    _commit(before, () => _Change('listAdd', itemPath));
    return itemPath;
  }

  @override
  bool removeListItem(String itemPath) {
    final before = document.captureState();
    final removed = document.removeListItem(itemPath);
    if (removed) _commit(before, () => _Change('listRemove', itemPath));
    return removed;
  }

  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) {
    final before = document.captureState();
    final childPath = SpecNodeCreator(model, document)
        .add(parentPath, childSegment, itemId: itemId);
    _commit(before, () => _Change('add', childPath));
    return childPath;
  }
}

void main() {
  late SpecModel model;
  late SpecDocument doc;
  late SpecQueryEngine engine;
  late _RecordingController controller;
  late DocTools tools;

  setUp(() {
    model = _model();
    doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'platform overview');
    doc.setContent('PD00/SIT/DET', 'current situation analysis');
    engine = SpecQueryEngine(model: model, document: doc);
    controller = _RecordingController(model, doc);
    tools = DocTools(engine: engine, controller: controller, pageSize: 2);
  });

  group('doc_search', () {
    test('a text query returns compact-JSON matches', () {
      final page = tools.search(const SpecQuery(text: 'platform'));
      expect(page.matches.map((m) => m.path), containsAll(['PD00/VIS', 'PD00/SUM']));

      final json = page.toJson();
      expect(json['cursorId'], isNotEmpty);
      expect(json['matches'], isA<List<Object?>>());
      final first = (json['matches'] as List).first as Map<String, Object?>;
      expect(first['path'], isA<String>());
      expect(first['kind'], 'content');
      expect(first['snippet'], contains('platform'));
    });
  });

  group('doc_search_iterate', () {
    test('a stable cursor paginates the §6 facility', () {
      // Three content nodes; pageSize 2 → page1 of 2 (more), page2 of 1 (done).
      final page1 = tools.search(const SpecQuery(kinds: {SpecNodeKind.content}));
      expect(page1.matches, hasLength(2));
      expect(page1.done, isFalse);

      final page2 = tools.iterate(page1.cursorId);
      expect(page2.matches, hasLength(1));
      expect(page2.done, isTrue);

      // An exhausted cursor is dropped — iterating it again is an error.
      expect(() => tools.iterate(page1.cursorId), throwsArgumentError);
    });

    test('an unknown cursor id is rejected', () {
      expect(() => tools.iterate('cur-nope'), throwsArgumentError);
    });
  });

  group('doc_reflect', () {
    test('reports a container node\'s allowed children + class facts', () {
      final r = tools.reflect('PD00/SIT');
      expect(r.resolved, isTrue);
      expect(r.classId, 'CurrentSituation');
      expect(r.mapsTo, 'PD00');
      expect(r.detailedIn, 'CS00');
      expect(r.annotations.map((a) => a.name), contains('MapsTo'));
      expect(r.allowedChildren.map((c) => c.segment), contains('DET'));

      final json = r.toJson();
      expect(json['classId'], 'CurrentSituation');
      expect(json['allowedChildren'], isA<List<Object?>>());
    });

    test('reports list element type + section-id pattern on the parent', () {
      final r = tools.reflect('PD00');
      final risks = r.allowedChildren.firstWhere((c) => c.segment == 'RSK');
      expect(risks.kind, SpecFieldKind.list);
      expect(risks.elementType, 'Risk');
      expect(risks.sectionIdPattern, isNotNull);
    });

    test('an unresolved path reports resolved:false', () {
      final r = tools.reflect('PD00/NOPE');
      expect(r.resolved, isFalse);
      expect(r.toJson()['resolved'], isFalse);
    });
  });

  group('doc_add_node', () {
    test('a legal add lands in the one change log', () {
      final result = tools.addNode('PD00', 'RSK');
      expect(result.ok, isTrue);
      expect(result.path, 'PD00/RSK-1');
      // The mutation landed in the controller's change log exactly once.
      expect(controller.log, [const _Change('add', 'PD00/RSK-1')]);
      expect(doc.listItems('PD00/RSK'), ['PD00/RSK-1']);
    });

    test('an illegal add returns a coded error and mutates nothing', () {
      final result = tools.addNode('PD00', 'NOPE');
      expect(result.ok, isFalse);
      expect(result.code, 'unknownChild');
      expect(result.toJson()['ok'], isFalse);
      expect(controller.log, isEmpty);
    });

    test('an initial content payload populates the new leaf in one burst '
        '(item 17)', () {
      final result = tools.addNode('PD00', 'RSK', content: 'initial risk text');
      expect(result.ok, isTrue);
      expect(result.path, 'PD00/RSK-1');
      // The list item's title leaf is set on creation? No — content lands on the
      // created node path itself. The created node is the list item; its content
      // value is recorded in the same change-log burst as the add.
      expect(doc.content('PD00/RSK-1'), 'initial risk text');
      expect(controller.log, [
        const _Change('add', 'PD00/RSK-1'),
        const _Change('content', 'PD00/RSK-1'),
      ]);
    });

    test('an empty initial content payload is not applied (no-op leaf)', () {
      final result = tools.addNode('PD00', 'RSK', content: '');
      expect(result.ok, isTrue);
      // Only the add lands; an empty content is skipped rather than recorded.
      expect(controller.log, [const _Change('add', 'PD00/RSK-1')]);
    });

    test('an initial fields payload sets each form field in the one change log '
        '(item 17)', () {
      final result = tools.addNode(
        'PD00',
        'RSK',
        fields: const {'severity': 'high', 'owner': 'platform'},
      );
      expect(result.ok, isTrue);
      expect(result.path, 'PD00/RSK-1');
      expect(doc.formField('PD00/RSK-1', 'severity'), 'high');
      expect(doc.formField('PD00/RSK-1', 'owner'), 'platform');
      expect(controller.log, [
        const _Change('add', 'PD00/RSK-1'),
        const _Change('form:severity', 'PD00/RSK-1'),
        const _Change('form:owner', 'PD00/RSK-1'),
      ]);
    });

    test('an illegal add never applies the initial payload', () {
      final result = tools.addNode('PD00', 'NOPE', content: 'ignored');
      expect(result.ok, isFalse);
      expect(controller.log, isEmpty);
    });
  });
}
