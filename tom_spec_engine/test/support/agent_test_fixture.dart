/// Shared test fixture for the §10 agent substrates (plan steps 15–16).
///
/// Both [AgentSubstrate] modes — (a) [DirectAgentSubstrate] and (b)
/// [BrainAgentSubstrate] — must drive the *same* complex agent procedure
/// through the *same* search → recall → edit → verify loop (the plan's step-16
/// "same loop test"). This file owns the single fixture both suites build on so
/// that "the same loop" is literally the same code: the model, the
/// change-log-recording controller, and the wired [AgentToolsApi].
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Builds the small `ProjectDefinition` model the agent loop edits.
///
/// `risks` is intentionally the **first** field and an addable list, so the
/// procedure's autonomous "first model-permitted child" selection lands on it.
SpecModel buildAgentTestModel() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {
          'type': 'ProjectDefinition',
          'title': 'Project Definition',
          'sectionId': 'PD00',
        },
      ],
      'classes': {
        'ProjectDefinition': {
          'name': 'ProjectDefinition',
          'sectionId': 'PD00',
          'fields': [
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

/// A single change-log entry the loop's done-criterion compares against.
class Change {
  /// The kind of mutation (`add`, `content`, …).
  final String kind;

  /// The structural path the mutation landed on.
  final String path;

  /// Creates an entry.
  const Change(this.kind, this.path);

  @override
  bool operator ==(Object other) =>
      other is Change && other.kind == kind && other.path == path;

  @override
  int get hashCode => Object.hash(kind, path);

  @override
  String toString() => 'Change($kind, $path)';
}

/// A faithful stand-in for the live controller: records one change-log entry per
/// effective mutation (the §5 "one change log" discipline).
class RecordingController implements SpecController {
  /// Creates a controller over [model] and [document].
  RecordingController(this.model, this.document);

  /// The meta-model the constrained add validates against.
  final SpecModel model;

  /// The live document every mutation lands on.
  final SpecDocument document;

  /// The ordered change log — one entry per effective mutation.
  final List<Change> log = [];

  void _commit(SpecDocumentState before, Change Function() entry) {
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
    _commit(before, () => Change('content', path));
  }

  @override
  void setFormField(String path, String field, String value) {
    final before = document.captureState();
    document.setFormField(path, field, value);
    _commit(before, () => Change('form:$field', path));
  }

  @override
  String addListItem(String listPath) {
    final before = document.captureState();
    final itemPath = document.addListItem(listPath);
    _commit(before, () => Change('listAdd', itemPath));
    return itemPath;
  }

  @override
  bool removeListItem(String itemPath) {
    final before = document.captureState();
    final removed = document.removeListItem(itemPath);
    if (removed) _commit(before, () => Change('listRemove', itemPath));
    return removed;
  }

  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) {
    final before = document.captureState();
    final childPath = SpecNodeCreator(model, document)
        .add(parentPath, childSegment, itemId: itemId);
    _commit(before, () => Change('add', childPath));
    return childPath;
  }
}

/// A fully wired agent fixture: the model, the live document seeded with two
/// content sections, the change-log-recording controller, and the
/// [AgentToolsApi] both substrate modes drive.
class AgentFixture {
  /// Creates the fixture from its parts.
  AgentFixture({
    required this.model,
    required this.document,
    required this.controller,
    required this.tools,
  });

  /// The meta-model.
  final SpecModel model;

  /// The live document.
  final SpecDocument document;

  /// The change-log-recording controller.
  final RecordingController controller;

  /// The unified agent tool surface.
  final AgentToolsApi tools;
}

/// Builds a fresh [AgentFixture] — fresh model/document/controller/tools — so
/// each substrate run starts from an identical, un-mutated state.
AgentFixture buildAgentFixture() {
  final model = buildAgentTestModel();
  final doc = SpecDocument();
  doc.setContent('PD00/VIS', 'resilient rollout platform');
  doc.setContent('PD00/SUM', 'platform overview');
  final engine = SpecQueryEngine(model: model, document: doc);
  final controller = RecordingController(model, doc);
  final docTools = DocTools(engine: engine, controller: controller);
  final index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
  final memTools = MemoryTools(recall: SpecRecall(index: index));
  final tools = AgentToolsApi(doc: docTools, memory: memTools);
  return AgentFixture(
    model: model,
    document: doc,
    controller: controller,
    tools: tools,
  );
}
