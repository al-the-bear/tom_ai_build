import 'package:test/test.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 7 / `llm_and_d4rt_tools.md` §5: the `spec` base scope binds the
/// document editing API to the **live controller**, so a script mutation is
/// indistinguishable from a tool mutation — it produces the *same* change-log
/// entry and undo snapshot.
///
/// The live controller is the Flutter `SpecDocumentController`, which the engine
/// cannot depend on. Step 7 therefore defines the engine-side [SpecController]
/// port the real controller will satisfy, and proves the binding against a
/// [_RecordingController] stub that records exactly what the real controller
/// records (a change-log entry + an undo snapshot per non-no-op mutation).

/// A self-contained model: a single-valued `content` leaf (`vision`), a complex
/// list with a `@SectionIdPattern` (`risks`), and a scalar list (`tags`).
SpecModel _model() {
  final risk = SpecClass(
    name: 'Risk',
    fields: [
      SpecField(name: 'title', kind: SpecFieldKind.content, sectionId: 'RISK-TITLE'),
    ],
  );
  final pd = SpecClass(
    name: 'ProjectDefinition',
    sectionId: 'PD00',
    fields: [
      SpecField(name: 'vision', kind: SpecFieldKind.content, sectionId: 'PD00-VIS'),
      SpecField(
        name: 'risks',
        kind: SpecFieldKind.list,
        sectionId: 'PD00-RISK',
        sectionIdPattern: r'PD00-RISK-\d+',
        elementType: 'Risk',
        elementIsComplex: true,
      ),
      SpecField(
        name: 'tags',
        kind: SpecFieldKind.list,
        sectionId: 'PD00-TAG',
        elementType: 'String',
      ),
    ],
  );
  return SpecModel(
    roots: [SpecRoot(type: 'ProjectDefinition', title: 'PD', sectionId: 'PD00')],
    classes: {'ProjectDefinition': pd, 'Risk': risk},
  );
}

/// One recorded change-log entry — the subset of the real controller's
/// `ChangeEntry` that the done-criterion compares (path, kind, before, after).
class _Change {
  final String kind;
  final String path;
  final String? before;
  final String? after;
  const _Change(this.kind, this.path, this.before, this.after);

  @override
  bool operator ==(Object other) =>
      other is _Change &&
      other.kind == kind &&
      other.path == path &&
      other.before == before &&
      other.after == after;

  @override
  int get hashCode => Object.hash(kind, path, before, after);

  @override
  String toString() => '_Change($kind, $path, $before -> $after)';
}

/// A faithful stand-in for the live `SpecDocumentController`: it wraps a
/// [SpecModel] + [SpecDocument] and, on every *effective* mutation, records a
/// change-log entry **and** pushes the before-snapshot onto an undo stack —
/// exactly the `_commit` discipline the real controller uses.
class _RecordingController implements SpecController {
  _RecordingController(this.model, this.document);

  final SpecModel model;
  final SpecDocument document;

  final List<_Change> log = [];
  final List<SpecDocumentState> undo = [];

  void _commit(SpecDocumentState before, _Change Function() entry) {
    final after = document.captureState();
    if (before.fingerprint == after.fingerprint) return;
    undo.add(before);
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
    final beforeVal = document.content(path);
    document.setContent(path, value);
    _commit(before,
        () => _Change('content', path, beforeVal, value.isEmpty ? null : value));
  }

  @override
  void setFormField(String path, String field, String value) {
    final before = document.captureState();
    final beforeVal = document.formField(path, field);
    document.setFormField(path, field, value);
    _commit(
        before,
        () => _Change('form:$field', path, beforeVal,
            value.isEmpty ? null : value));
  }

  @override
  String addListItem(String listPath) {
    final before = document.captureState();
    final itemPath = document.addListItem(listPath);
    _commit(before, () => _Change('listAdd', itemPath, null, itemPath));
    return itemPath;
  }

  @override
  bool removeListItem(String itemPath) {
    final before = document.captureState();
    final removed = document.removeListItem(itemPath);
    if (removed) {
      _commit(before, () => _Change('listRemove', itemPath, itemPath, null));
    }
    return removed;
  }

  @override
  String addChild(String parentPath, String childSegment, {String? itemId}) {
    final before = document.captureState();
    final childPath = SpecNodeCreator(model, document)
        .add(parentPath, childSegment, itemId: itemId);
    _commit(before, () => _Change('add', childPath, null, childPath));
    return childPath;
  }
}

/// Builds a controller over a fresh model + empty document.
_RecordingController _controller() =>
    _RecordingController(_model(), SpecDocument());

/// Runs [source] in a fresh interpreter granted [scope].
Object? _run(ScriptScope scope, String source) {
  final registry = ScopeRegistry()..register(scope);
  final env = registry.build([scope.name]);
  final d4rt = D4rt();
  env.applyTo(d4rt);
  return d4rt.execute(source: source);
}

const _import = "import 'package:tom_spec_engine/spec_api.dart';";
const _modelImport = "import 'package:tom_spec_engine/spec_model_api.dart';";
const _searchImport = "import 'package:tom_spec_engine/spec_search_api.dart';";

void main() {
  group('specScope shape', () {
    test('is a scope named "spec" exposing the spec_api library', () {
      final scope = specScope(_controller());
      expect(scope.name, 'spec');
      expect(scope.libraries.map((l) => l.name), contains('spec_api'));
    });
  });

  group('a script mutation equals a tool mutation', () {
    test('setContent: same change-log entry and undo snapshot', () {
      // Tool path: call the controller directly.
      final tool = _controller();
      tool.setContent('PD00/PD00-VIS', 'a clear vision');

      // Script path: a sandboxed script under the spec scope does the same.
      final scripted = _controller();
      _run(specScope(scripted), '''
$_import
main() {
  spec.setContent('PD00/PD00-VIS', 'a clear vision');
}
''');

      expect(scripted.log, equals(tool.log));
      expect(scripted.document.content('PD00/PD00-VIS'), 'a clear vision');
      expect(scripted.undo, hasLength(tool.undo.length));
      expect(scripted.undo.single.fingerprint, tool.undo.single.fingerprint);
    });

    test('addListItem: same entry and the script sees the new item path', () {
      final tool = _controller();
      final toolPath = tool.addListItem('PD00/PD00-TAG');

      final scripted = _controller();
      final result = _run(specScope(scripted), '''
$_import
main() => spec.addListItem('PD00/PD00-TAG');
''');

      expect(result, toolPath);
      expect(scripted.log, equals(tool.log));
      expect(scripted.listItems('PD00/PD00-TAG'), [toolPath]);
    });

    test('a no-op edit records nothing, exactly like the tool path', () {
      final tool = _controller()..setContent('PD00/PD00-VIS', '');
      final scripted = _controller();
      _run(specScope(scripted), '''
$_import
main() { spec.setContent('PD00/PD00-VIS', ''); }
''');
      expect(tool.log, isEmpty);
      expect(scripted.log, isEmpty);
      expect(scripted.undo, isEmpty);
    });
  });

  group('constrained node creation routes through the controller', () {
    test('a legal complex-list add records one entry', () {
      final scripted = _controller();
      final childPath = _run(specScope(scripted), '''
$_import
main() => spec.addChild('PD00', 'PD00-RISK');
''');
      expect(childPath, 'PD00/PD00-RISK-1');
      expect(scripted.log, [const _Change('add', 'PD00/PD00-RISK-1', null, 'PD00/PD00-RISK-1')]);
      expect(scripted.listItems('PD00/PD00-RISK'), ['PD00/PD00-RISK-1']);
    });

    test('an illegal add surfaces as a script error and mutates nothing', () {
      final scripted = _controller();
      expect(
        () => _run(specScope(scripted), '''
$_import
main() => spec.addChild('PD00', 'PD00-NOPE');
'''),
        throwsA(anything),
      );
      expect(scripted.log, isEmpty);
      expect(scripted.document.listItems('PD00/PD00-RISK'), isEmpty);
    });
  });

  group('read-back through the facade', () {
    test('a script reads a value a prior tool edit wrote', () {
      final controller = _controller()
        ..setContent('PD00/PD00-VIS', 'written by a tool');
      final read = _run(specScope(controller), '''
$_import
main() => spec.content('PD00/PD00-VIS');
''');
      expect(read, 'written by a tool');
    });
  });

  group('the read-only `model` reflection global (followup item 11)', () {
    ScriptScope reflectingScope(_RecordingController c) =>
        specScope(c, model: () => c.model);

    test('scope exposes spec_model_api only when a model provider is given', () {
      final without = specScope(_controller());
      expect(without.libraries.map((l) => l.name),
          isNot(contains('spec_model_api')));

      final with_ = reflectingScope(_controller());
      expect(with_.libraries.map((l) => l.name), contains('spec_model_api'));
    });

    test('resolves / kindOf / classOf / sectionId reflect the meta-model', () {
      final c = _controller();
      final out = _run(reflectingScope(c), '''
$_modelImport
main() => [
  model.resolves('PD00'),
  model.resolves('PD00/PD00-NOPE'),
  model.kindOf('PD00/PD00-VIS'),
  model.classOf('PD00'),
  model.sectionId('PD00/PD00-VIS'),
];
''');
      expect(out, [true, false, 'content', 'ProjectDefinition', 'PD00-VIS']);
    });

    test('allowedChildren lists the model-permitted segments of a node', () {
      final c = _controller();
      final out = _run(reflectingScope(c), '''
$_modelImport
main() => [for (final ch in model.allowedChildren('PD00')) ch['segment']];
''');
      expect(out, containsAll(<String>['PD00-VIS', 'PD00-RISK', 'PD00-TAG']));
    });

    test('reflect returns the full JSON-friendly node descriptor', () {
      final c = _controller();
      final out = _run(reflectingScope(c), '''
$_modelImport
main() => model.reflect('PD00');
''') as Map;
      expect(out['resolved'], true);
      expect(out['classId'], 'ProjectDefinition');
      expect(out['sectionId'], 'PD00');
    });

    test('a null-returning provider injects no model global', () {
      final c = _controller();
      expect(
        () => _run(specScope(c, model: () => null), '''
$_modelImport
main() => model.resolves('PD00');
'''),
        throwsA(anything),
      );
      expect(c.log, isEmpty);
    });
  });

  group('the read-only `search` grep global (followup item 12)', () {
    SpecQueryEngine engineOf(_RecordingController c) =>
        SpecQueryEngine(model: c.model, document: c.document);

    ScriptScope searchingScope(_RecordingController c) =>
        specScope(c, search: () => engineOf(c));

    test('scope exposes spec_search_api only when a search provider is given',
        () {
      final without = specScope(_controller());
      expect(without.libraries.map((l) => l.name),
          isNot(contains('spec_search_api')));

      final with_ = searchingScope(_controller());
      expect(with_.libraries.map((l) => l.name), contains('spec_search_api'));
    });

    test('grep pages matches the live document carries as JSON maps', () {
      final c = _controller()
        ..setContent('PD00/PD00-VIS', 'a bold and clear vision');
      final out = _run(searchingScope(c), '''
$_searchImport
main() {
  final cur = search.grep('bold');
  return cur.toList();
}
''') as List;
      expect(out, hasLength(1));
      final match = out.single as Map;
      expect(match['path'], 'PD00/PD00-VIS');
      expect(match['kind'], 'content');
    });

    test('query honours the full §6 dimensions (kinds + text)', () {
      final c = _controller()
        ..setContent('PD00/PD00-VIS', 'shared keyword here');
      final out = _run(searchingScope(c), '''
$_searchImport
main() {
  final cur = search.query({'text': 'keyword', 'kinds': ['content']});
  return cur.count();
}
''');
      expect(out, 1);
    });

    test('next + take page a cursor forward', () {
      final c = _controller()
        ..setContent('PD00/PD00-VIS', 'alpha beta gamma');
      final out = _run(searchingScope(c), '''
$_searchImport
main() {
  final cur = search.grep('alpha');
  final first = cur.next();
  final rest = cur.take(5);
  return [first == null, rest.length];
}
''') as List;
      expect(out, [false, 0]);
    });

    test('an unknown kind surfaces as a script error', () {
      final c = _controller();
      expect(
        () => _run(searchingScope(c), '''
$_searchImport
main() => search.query({'kinds': ['nonsense']}).toList();
'''),
        throwsA(anything),
      );
    });

    test('a null-returning provider injects no search global', () {
      final c = _controller();
      expect(
        () => _run(specScope(c, search: () => null), '''
$_searchImport
main() => search.grep('x').toList();
'''),
        throwsA(anything),
      );
      expect(c.log, isEmpty);
    });
  });
}
