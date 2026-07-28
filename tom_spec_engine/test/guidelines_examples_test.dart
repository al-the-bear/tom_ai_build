// Contract: the worked examples in the agent guidelines
// (`tom_ai/ai_build/tom_specs_model/doc/llm_guidelines_specification.md` §6)
// actually run against the shipped engine surface.
//
// Each `const` source below is the **verbatim** script body printed in the
// guidelines. Running them here keeps the document honest: a signature drift in
// the `spec` / `files` / `memory` scope API breaks this test, not just the prose.

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

// --- The `llm_guidelines_specification.md` §6 example sources ---------------
// (verbatim copies of the guidelines)

/// `llm_guidelines_specification.md` §6.1 — iterate a list and flag empty
/// members (spec scope).
const example61 = '''
import 'package:tom_spec_engine/spec_api.dart';

// Ensure two risks exist, fill one title, then flag every still-empty title.
main() {
  final a = spec.addChild('PD00', 'PD00-RISK'); // -> PD00/PD00-RISK-1
  spec.addChild('PD00', 'PD00-RISK'); //           -> PD00/PD00-RISK-2
  spec.setContent('\$a/RISK-TITLE', 'Vendor lock-in');

  var flagged = 0;
  for (final item in spec.listItems('PD00/PD00-RISK')) {
    final titlePath = '\$item/RISK-TITLE';
    if ((spec.content(titlePath) ?? '').isEmpty) {
      spec.setContent(titlePath, '_TODO: name this risk._');
      flagged++;
    }
  }
  return {'risks': spec.listItems('PD00/PD00-RISK').length, 'flagged': flagged};
}
''';

/// `llm_guidelines_specification.md` §6.2 — meta-model-validated add (spec
/// scope).
const example62 = '''
import 'package:tom_spec_engine/spec_api.dart';

// Add a risk; the engine validates the add against the model and throws on an
// illegal child, so there is nothing to pre-check.
main() {
  try {
    final path = spec.addChild('PD00', 'PD00-RISK');
    spec.setContent('\$path/RISK-TITLE', 'New requirement');
    return {'added': true, 'path': path};
  } catch (e) {
    return {'added': false, 'reason': e.toString()};
  }
}
''';

/// `llm_guidelines_specification.md` §6.3 — read any path, write only under
/// `agent/scratchpad` (files scope). `__NOTES__` is the only placeholder; the
/// guidelines show a literal path.
const example63 = '''
import 'package:tom_spec_engine/spec_files.dart';

// Read an external note (any path) and stage a summary into agent/scratchpad.
main() {
  final notes = files.readText(r'__NOTES__');
  final head = notes.split('\\n').take(3).join('\\n');
  files.writeText('agent/scratchpad/notes_head.md', head); // only writable root
  return {'bytes': head.length};
}
''';

/// `llm_guidelines_specification.md` §6.4 — semantic recall, read-only (memory
/// scope).
const example64 = '''
import 'package:tom_spec_engine/memory.dart';

// Recall the section paths most relevant to a question (semantic, read-only).
main() async {
  final paths = await memory.recallPaths('rollout platform', k: 5);
  return {'candidates': paths};
}
''';

// --- Harness -----------------------------------------------------------------

/// The model the spec-scope examples run against: a `vision` content leaf and a
/// `risks` complex list whose elements carry a `RISK-TITLE` content field.
SpecModel _specModel() {
  final risk = SpecClass(
    name: 'Risk',
    fields: [
      SpecField(
          name: 'title', kind: SpecFieldKind.content, sectionId: 'RISK-TITLE'),
    ],
  );
  final pd = SpecClass(
    name: 'ProjectDefinition',
    sectionId: 'PD00',
    fields: [
      SpecField(
          name: 'vision', kind: SpecFieldKind.content, sectionId: 'PD00-VIS'),
      SpecField(
        name: 'risks',
        kind: SpecFieldKind.list,
        sectionId: 'PD00-RISK',
        sectionIdPattern: r'PD00-RISK-\d+',
        elementType: 'Risk',
        elementIsComplex: true,
      ),
    ],
  );
  return SpecModel(
    roots: [SpecRoot(type: 'ProjectDefinition', title: 'PD', sectionId: 'PD00')],
    classes: {'ProjectDefinition': pd, 'Risk': risk},
  );
}

/// A minimal live-controller stand-in: routes the eight `SpecController`
/// operations to a backing [SpecDocument] (meta-model-validated creation via
/// [SpecNodeCreator]), exactly the surface the `spec` scope binds to.
class _Controller implements SpecController {
  _Controller(this.model, this.document);
  final SpecModel model;
  final SpecDocument document;

  @override
  String? content(String path) => document.content(path);
  @override
  String? formField(String path, String field) =>
      document.formField(path, field);
  @override
  List<String> listItems(String listPath) => document.listItems(listPath);
  @override
  void setContent(String path, String value) =>
      document.setContent(path, value);
  @override
  void setFormField(String path, String field, String value) =>
      document.setFormField(path, field, value);
  @override
  String addListItem(String listPath) => document.addListItem(listPath);
  @override
  bool removeListItem(String itemPath) => document.removeListItem(itemPath);
  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) =>
      SpecNodeCreator(model, document)
          .add(parentPath, childSegment, itemId: itemId);
}

Future<Object?> _run(ScriptScope scope, String source) async {
  final env = (ScopeRegistry()..register(scope)).build([scope.name]);
  final d4rt = D4rt();
  env.applyTo(d4rt);
  final result = d4rt.execute(source: source);
  return result is Future ? await result : result;
}

void main() {
  group('llm_guidelines_specification.md §6.1 find → iterate → flag '
      '(spec scope)', () {
    test('flags the one empty risk title, leaving the filled one', () async {
      final scope = specScope(_Controller(_specModel(), SpecDocument()));
      final result = await _run(scope, example61) as Map;
      expect(result['risks'], 2);
      expect(result['flagged'], 1);
    });
  });

  group('llm_guidelines_specification.md §6.2 meta-model-validated add '
      '(spec scope)', () {
    test('a legal add succeeds and returns the new path', () async {
      final scope = specScope(_Controller(_specModel(), SpecDocument()));
      final result = await _run(scope, example62) as Map;
      expect(result['added'], isTrue);
      expect(result['path'], 'PD00/PD00-RISK-1');
    });
  });

  group('llm_guidelines_specification.md §6.3 read anywhere, write '
      'scratchpad only (files scope)', () {
    test('reads an external note and stages its head under scratchpad',
        () async {
      final ws = Directory.systemTemp.createTempSync('tse_guidelines_ws_');
      final notes = File('${ws.path}/notes.md')
        ..writeAsStringSync('line1\nline2\nline3\nline4');
      addTearDown(() => ws.deleteSync(recursive: true));

      final scope = filesScope(SpecFileFacade(workspaceRoot: ws.path));
      final source = example63.replaceAll('__NOTES__', notes.path);
      final result = await _run(scope, source) as Map;

      expect(result['bytes'], 'line1\nline2\nline3'.length);
      expect(File('${ws.path}/agent/scratchpad/notes_head.md').readAsStringSync(),
          'line1\nline2\nline3');
    });
  });

  group('llm_guidelines_specification.md §6.4 semantic recall '
      '(memory scope)', () {
    test('recalls candidate paths, read-only', () async {
      final doc = SpecDocument()
        ..setContent('PD00/PD00-VIS', 'resilient rollout platform');
      final engine = SpecQueryEngine(model: _specModel(), document: doc);
      final index = StructuralLexicalIndex()..rebuild(engine.projectNodes());
      final scope = memoryScope(SpecRecall(index: index));

      final result = await _run(scope, example64) as Map;
      expect(result['candidates'], contains('PD00/PD00-VIS'));
    });
  });
}
