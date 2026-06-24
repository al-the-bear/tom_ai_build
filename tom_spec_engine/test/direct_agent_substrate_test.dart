import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 15 (`d4rt_and_llm_tools_plan.md`) / §10 — the **`AgentSubstrate`**
/// abstraction + **mode (a)** (direct Agent SDK, augmented with Tom Brain
/// named memory, driven by a **complex agent procedure**: a D4rt procedure over
/// the §8 tools).
///
/// Done-criterion: the procedure drives a **search → recall → edit → verify**
/// loop in a test harness, and the edit (the mutating tool) lands in the **one
/// change log**.
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
            // risks first → the procedure's autonomous "first allowed child"
            // selection lands on an addable list.
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'RSK',
              'sectionIdPattern': r'PD00/RSK-\d+',
              'elementType': 'Risk',
              'elementIsComplex': true,
            },
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS'},
            {'name': 'summary', 'kind': 'content', 'sectionId': 'SUM'},
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
  late _RecordingController controller;
  late AgentToolsApi tools;
  late DirectAgentSubstrate substrate;

  setUp(() {
    model = _model();
    doc = SpecDocument();
    doc.setContent('PD00/VIS', 'resilient rollout platform');
    doc.setContent('PD00/SUM', 'platform overview');
    final engine = SpecQueryEngine(model: model, document: doc);
    controller = _RecordingController(model, doc);
    final docTools = DocTools(engine: engine, controller: controller);
    final index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
    final memTools = MemoryTools(recall: SpecRecall(index: index));
    tools = AgentToolsApi(doc: docTools, memory: memTools);
    substrate = DirectAgentSubstrate(tools: tools);
  });

  test('reports mode "direct"', () {
    expect(substrate.mode, 'direct');
  });

  group('the complex agent procedure', () {
    test('drives search → recall → edit → verify and the edit lands in the '
        'one change log', () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00', 'childSegment': 'RSK'},
      ));

      expect(result.ok, isTrue, reason: result.error);
      // The procedure's `main()` returns a D4rt map literal
      // (`Map<Object?, Object?>` with String keys) — JSON-able, but cast
      // through the dynamic Map view like every other D4rt return.
      final out = (result.output as Map).cast<String, Object?>();

      // SEARCH surfaced the matching content sections.
      expect(out['searched'], contains('PD00/SUM'));
      // RECALL surfaced at least one section from memory.
      expect(out['recalled'], isNotEmpty);
      // EDIT created the list item …
      expect(out['added'], 'PD00/RSK-1');
      // … VERIFY confirmed it resolves in the model.
      expect(out['verified'], isTrue);

      // The mutation landed in the controller's change log exactly once.
      expect(controller.log, [const _Change('add', 'PD00/RSK-1')]);
      expect(doc.listItems('PD00/RSK'), ['PD00/RSK-1']);

      // The result is JSON-able for the MCP surface.
      expect(result.toJson()['ok'], isTrue);
    });

    test('autonomously picks the first model-permitted child when none is '
        'given', () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00'},
      ));

      expect(result.ok, isTrue, reason: result.error);
      // The procedure's `main()` returns a D4rt map literal
      // (`Map<Object?, Object?>` with String keys) — JSON-able, but cast
      // through the dynamic Map view like every other D4rt return.
      final out = (result.output as Map).cast<String, Object?>();
      // The first allowed child of PD00 is the risks list (segment RSK).
      expect(out['childSegment'], 'RSK');
      expect(out['added'], 'PD00/RSK-1');
      expect(controller.log, [const _Change('add', 'PD00/RSK-1')]);
    });

    test('a meta-model-rejected edit is handled gracefully (ok:false output, '
        'no throw, empty change log)', () async {
      final result = await substrate.run(const AgentTask(
        goal: 'platform',
        inputs: {'parentPath': 'PD00', 'childSegment': 'NOPE'},
      ));

      // The run itself did not throw …
      expect(result.ok, isTrue);
      // The procedure's `main()` returns a D4rt map literal
      // (`Map<Object?, Object?>` with String keys) — JSON-able, but cast
      // through the dynamic Map view like every other D4rt return.
      final out = (result.output as Map).cast<String, Object?>();
      // … but the procedure reports the rejected edit with its code.
      expect(out['ok'], isFalse);
      expect(out['code'], 'unknownChild');
      // Nothing was mutated.
      expect(controller.log, isEmpty);
    });
  });

  test('a procedure that throws surfaces on the error channel', () async {
    final broken = DirectAgentSubstrate(
      tools: tools,
      procedure: const AgentProcedure(
        name: 'broken',
        source: '''
import 'package:tom_spec_engine/agent.dart';
main(task) => undefinedSymbol();
''',
      ),
    );

    final result = await broken.run(const AgentTask(goal: 'x'));
    expect(result.ok, isFalse);
    expect(result.error, isNotNull);
  });
}
