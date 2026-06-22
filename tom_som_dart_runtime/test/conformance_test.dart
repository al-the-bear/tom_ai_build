/// Conformance harness for the **language-agnostic** spec-runtime corpus
/// (`../tom_som_conformance/corpus`, plan item #8).
///
/// The Dart runtime is the reference implementation: this test *builds* the
/// shared corpus from the live runtime (set `UPDATE_CORPUS=1` to (re)write the
/// committed fixtures) and, on every run, *verifies* the reference reproduces
/// every golden byte-for-byte. Every other language's `tom_som_<lang>_runtime`
/// is validated against the same committed corpus by its own conformance
/// runner, so "passes the same fixtures as Dart" is an objective contract.
///
/// Coverage mirrors the plan's done-condition: read/write, list add/remove,
/// form fields, validation, reflection resolution, and byte-stable YAML +
/// Markdown round-trips.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  // The corpus lives next to this package so every language port reads the
  // identical fixtures. `Directory.current` is the package root under `test`.
  final corpusDir = Directory(
      '${Directory.current.path}/../tom_som_conformance/corpus');
  final update = Platform.environment['UPDATE_CORPUS'] == '1';

  const stamp = '1.0';
  final meta = _buildMeta();
  final model = SpecModel.fromJson(meta);
  final doc = _buildDocument();
  final state = doc.toJson();

  final yamlGolden =
      SpecDocumentYaml.encode(document: doc, modelVersion: stamp);
  final mdGolden = SpecDocumentMarkdown(model, doc).exportRoot(model.roots.first);

  final reflectionCases = _reflectionCases(model);
  final validationCases = _validationCases(model);
  final operationsCases = _operationsScript();

  setUpAll(() {
    if (!update) return;
    corpusDir.createSync(recursive: true);
    const enc = JsonEncoder.withIndent('  ');
    void write(String name, String body) =>
        File('${corpusDir.path}/$name').writeAsStringSync(body);
    write('model.meta.json', '${enc.convert(meta)}\n');
    write('state.json', '${enc.convert(state)}\n');
    write('expected.docspecs.yaml', yamlGolden);
    write('expected.md', mdGolden);
    write('reflection_cases.json', '${enc.convert(reflectionCases)}\n');
    write('validation_cases.json', '${enc.convert(validationCases)}\n');
    write('operations_cases.json', '${enc.convert(operationsCases)}\n');
  });

  String read(String name) =>
      File('${corpusDir.path}/$name').readAsStringSync();

  test('model.meta.json round-trips through SpecModel unchanged', () {
    final onDisk =
        jsonDecode(read('model.meta.json')) as Map<String, dynamic>;
    final reloaded = SpecModel.fromJson(onDisk);
    expect(reloaded.roots.map((r) => r.type), model.roots.map((r) => r.type));
    expect(reloaded.classes.keys.toSet(), model.classes.keys.toSet());
  });

  test('state.json matches the live document toJson()', () {
    final onDisk = jsonDecode(read('state.json')) as Map<String, dynamic>;
    expect(onDisk, state);
    // And it reloads into an equal document.
    final reloaded = SpecDocument()..loadJson(onDisk);
    expect(reloaded.toJson(), state);
  });

  test('YAML encode is byte-stable against the committed golden', () {
    expect(SpecDocumentYaml.encode(document: doc, modelVersion: stamp),
        read('expected.docspecs.yaml'));
  });

  test('YAML decode→memory→encode is byte-stable and preserves the stamp', () {
    final golden = read('expected.docspecs.yaml');
    final decoded = SpecDocumentYaml.decode(golden);
    expect(decoded.modelVersion, stamp);
    final reDoc = SpecDocument()..loadJson(decoded.document);
    expect(SpecDocumentYaml.encode(document: reDoc, modelVersion: stamp),
        golden);
  });

  test('Markdown export is byte-stable against the committed golden', () {
    expect(SpecDocumentMarkdown(model, doc).exportRoot(model.roots.first),
        read('expected.md'));
  });

  test('Markdown parse→memory→export is clean and byte-stable', () {
    final golden = read('expected.md');
    final parsed = SpecDocumentMarkdown(model, doc).parse(golden);
    expect(parsed.rejections, isEmpty,
        reason: parsed.rejections.join('\n'));
    final reDoc = SpecDocument()
      ..loadJson({
        'content': parsed.content,
        'forms': parsed.forms,
        'lists': parsed.lists,
      });
    expect(SpecDocumentMarkdown(model, reDoc).exportRoot(model.roots.first),
        golden);
  });

  test('reflection cases match the committed expectations', () {
    final cases = jsonDecode(read('reflection_cases.json')) as List;
    final refl = SpecReflection(model);
    for (final c in cases.cast<Map<String, dynamic>>()) {
      final res = refl.resolve(c['path'] as String);
      expect(res != null, c['resolves'], reason: 'resolves ${c['path']}');
      if (res == null) continue;
      expect(res.kind.name, c['kind'], reason: 'kind ${c['path']}');
      expect(res.field?.name, c['field'], reason: 'field ${c['path']}');
      expect(res.targetClass?.name, c['targetClass'],
          reason: 'class ${c['path']}');
      expect(res.isValueLeaf, c['isValueLeaf'], reason: 'leaf ${c['path']}');
    }
  });

  test('validation cases match the committed expectations', () {
    final cases = jsonDecode(read('validation_cases.json')) as List;
    for (final c in cases.cast<Map<String, dynamic>>()) {
      final d = SpecDocument()..loadJson(c['state'] as Map);
      final errs = validateDocument(model, d)
          .map((e) => {'path': e.path, 'code': e.code.name})
          .toList();
      expect(errs, c['errors'], reason: 'validation ${c['name']}');
    }
  });

  test('operations script replays with the committed results', () {
    final steps = jsonDecode(read('operations_cases.json')) as List;
    final d = SpecDocument();
    for (final s in steps.cast<Map<String, dynamic>>()) {
      switch (s['op']) {
        case 'isEmpty':
          expect(d.isEmpty, s['expect']);
        case 'setContent':
          d.setContent(s['path'] as String, s['value'] as String);
        case 'content':
          expect(d.content(s['path'] as String), s['expect']);
        case 'setFormField':
          d.setFormField(
              s['path'] as String, s['field'] as String, s['value'] as String);
        case 'formField':
          expect(d.formField(s['path'] as String, s['field'] as String),
              s['expect']);
        case 'addListItem':
          expect(d.addListItem(s['listPath'] as String), s['expect']);
        case 'listItems':
          expect(d.listItems(s['listPath'] as String),
              (s['expect'] as List).cast<String>());
        case 'listItemCount':
          expect(d.listItemCount(s['listPath'] as String), s['expect']);
        case 'hasValuesUnder':
          expect(d.hasValuesUnder(s['prefix'] as String), s['expect']);
        case 'removeListItem':
          expect(d.removeListItem(s['itemPath'] as String), s['expect']);
        default:
          fail('unknown op ${s['op']}');
      }
    }
  });
}

// --- Fixture construction (the reference data the corpus is generated from) --

/// A compact, hand-authored meta-model that still exercises every field kind:
/// content (incl. a multi-line block-scalar value), enum, scalar, a two-field
/// `@Form`, a `@Min`-constrained complex list, a nested complex section, and a
/// (declared-but-unpopulated) scalar list for resolution coverage.
Map<String, dynamic> _buildMeta() => {
      'metaSchemaVersion': 1,
      'modelVersion': 1,
      'modelVersionLabel': 'demo-1.0',
      'roots': [
        {
          'type': 'Demo',
          'title': 'Demo Document',
          'sectionId': 'DEMO',
          'description': 'A compact conformance fixture.',
        }
      ],
      'classes': {
        'Demo': {
          'name': 'Demo',
          'sectionId': 'DEMO',
          'annotations': [
            {
              'name': 'Document',
              'arguments': {'title': 'Demo Document'}
            },
            {
              'name': 'SectionId',
              'arguments': {'id': 'DEMO'}
            },
          ],
          'fields': [
            {'name': 'title', 'kind': 'content', 'contentType': 'text'},
            {'name': 'summary', 'kind': 'content', 'contentType': 'markdown'},
            {
              'name': 'priority',
              'kind': 'enum',
              'enumType': 'Priority',
              'enumValues': ['low', 'high'],
            },
            {'name': 'count', 'kind': 'scalar', 'type': 'int'},
            {
              'name': 'details',
              'kind': 'form',
              'formFields': [
                {
                  'name': 'owner',
                  'label': 'Owner',
                  'type': 'String',
                  'required': true
                },
                {'name': 'contact', 'label': 'Contact', 'type': 'String'},
              ],
            },
            {
              'name': 'items',
              'kind': 'list',
              'elementType': 'Item',
              'elementIsComplex': true,
              'min': 2,
              'annotations': [
                {
                  'name': 'Min',
                  'arguments': {'value': 2}
                }
              ],
            },
            {'name': 'meta', 'kind': 'complex', 'type': 'Meta'},
          ],
        },
        'Item': {
          'name': 'Item',
          'fields': [
            {'name': 'label', 'kind': 'content'},
            {
              'name': 'status',
              'kind': 'enum',
              'enumType': 'Status',
              'enumValues': ['open', 'done'],
            },
          ],
        },
        'Meta': {
          'name': 'Meta',
          'fields': [
            {'name': 'owner', 'kind': 'content'},
            {
              'name': 'tags',
              'kind': 'list',
              'elementType': 'String',
              'elementIsComplex': false,
            },
          ],
        },
      },
    };

/// The populated document the YAML/Markdown goldens are rendered from. Built
/// through the public mutation API so the stored sequence numbers are real.
SpecDocument _buildDocument() {
  final d = SpecDocument();
  d.setContent('DEMO/title', 'Hello');
  d.setContent('DEMO/summary', 'Line one\nLine two\n\nLine four');
  d.setContent('DEMO/priority', 'high');
  d.setContent('DEMO/count', '3');
  d.setFormField('DEMO/details', 'owner', 'Bob');
  d.setFormField('DEMO/details', 'contact', 'bob@example.com');
  final i1 = d.addListItem('DEMO/items');
  d.setContent('$i1/label', 'First');
  d.setContent('$i1/status', 'open');
  final i2 = d.addListItem('DEMO/items');
  d.setContent('$i2/label', 'Second line A\nwith ```triple``` ticks');
  d.setContent('$i2/status', 'done');
  d.setContent('DEMO/meta/owner', 'alice');
  return d;
}

List<Map<String, dynamic>> _reflectionCases(SpecModel model) {
  final refl = SpecReflection(model);
  Map<String, dynamic> caseFor(String path) {
    final r = refl.resolve(path);
    return {
      'path': path,
      'resolves': r != null,
      'kind': r?.kind.name,
      'field': r?.field?.name,
      'targetClass': r?.targetClass?.name,
      'isValueLeaf': r?.isValueLeaf ?? false,
    };
  }

  return [
    'DEMO',
    'DEMO/title',
    'DEMO/summary',
    'DEMO/priority',
    'DEMO/count',
    'DEMO/details',
    'DEMO/items',
    'DEMO/items-1',
    'DEMO/items-1/label',
    'DEMO/items-1/status',
    'DEMO/meta',
    'DEMO/meta/owner',
    'DEMO/meta/tags',
    'DEMO/meta/tags-1',
    'DEMO/ghost',
    'DEMO/items-1/ghost',
    'WRONG',
  ].map(caseFor).toList();
}

List<Map<String, dynamic>> _validationCases(SpecModel model) {
  Map<String, dynamic> caseFor(String name, Map<String, Object?> state) {
    final d = SpecDocument()..loadJson(state);
    final errs = validateDocument(model, d)
        .map((e) => {'path': e.path, 'code': e.code.name})
        .toList();
    return {'name': name, 'state': state, 'errors': errs};
  }

  return [
    caseFor('valid', _buildDocument().toJson()),
    caseFor('dangling', {
      'content': {'DEMO/ghost': 'x'}
    }),
    caseFor('kindMismatch', {
      'content': {'DEMO/items': 'x'}
    }),
    caseFor('unknownFormField', {
      'forms': {
        'DEMO/details': {'bogus': 'v'}
      }
    }),
    caseFor('minItems', {
      'lists': {
        'DEMO/items': {
          'seq': 1,
          'items': ['DEMO/items-1']
        }
      }
    }),
  ];
}

/// A model-free sequence of document mutations with their expected results —
/// proves empty-clears, monotonic (never-reused) list sequence numbers, purge
/// on removal, and form/list bookkeeping.
List<Map<String, dynamic>> _operationsScript() => [
      {'op': 'isEmpty', 'expect': true},
      {'op': 'setContent', 'path': 'A/x', 'value': 'hi'},
      {'op': 'content', 'path': 'A/x', 'expect': 'hi'},
      {'op': 'isEmpty', 'expect': false},
      {'op': 'setContent', 'path': 'A/x', 'value': ''},
      {'op': 'content', 'path': 'A/x', 'expect': null},
      {'op': 'isEmpty', 'expect': true},
      {'op': 'setFormField', 'path': 'A/f', 'field': 'k', 'value': 'v'},
      {'op': 'formField', 'path': 'A/f', 'field': 'k', 'expect': 'v'},
      {'op': 'setFormField', 'path': 'A/f', 'field': 'k', 'value': ''},
      {'op': 'formField', 'path': 'A/f', 'field': 'k', 'expect': null},
      {'op': 'addListItem', 'listPath': 'A/l', 'expect': 'A/l-1'},
      {'op': 'addListItem', 'listPath': 'A/l', 'expect': 'A/l-2'},
      {'op': 'setContent', 'path': 'A/l-1/c', 'value': 'one'},
      {
        'op': 'listItems',
        'listPath': 'A/l',
        'expect': ['A/l-1', 'A/l-2']
      },
      {'op': 'listItemCount', 'listPath': 'A/l', 'expect': 2},
      {'op': 'hasValuesUnder', 'prefix': 'A/l-1', 'expect': true},
      {'op': 'removeListItem', 'itemPath': 'A/l-1', 'expect': true},
      {'op': 'hasValuesUnder', 'prefix': 'A/l-1', 'expect': false},
      {
        'op': 'listItems',
        'listPath': 'A/l',
        'expect': ['A/l-2']
      },
      {'op': 'addListItem', 'listPath': 'A/l', 'expect': 'A/l-3'},
      {'op': 'removeListItem', 'itemPath': 'A/l-9', 'expect': false},
    ];
