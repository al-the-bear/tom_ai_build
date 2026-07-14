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
  final tree = buildSomMetaTree(model);
  final doc = _buildDocument();
  final state = doc.toJson();

  final yamlGolden =
      SpecDocumentYaml.encode(document: doc, tree: tree, modelVersion: stamp);
  final mdGolden = SpecDocumentMarkdown(model, doc).exportRoot(model.roots.first);

  final reflectionCases = _reflectionCases(model);
  final validationCases = _validationCases(model);
  final operationsCases = _operationsScript();
  final sectionIdCases = _sectionIdCases();
  final serializationOrderCase = _serializationOrderCase();

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
    write('section_id_cases.json', '${enc.convert(sectionIdCases)}\n');
    write('serialization_order_cases.json',
        '${enc.convert(serializationOrderCase)}\n');
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
    expect(
        SpecDocumentYaml.encode(document: doc, tree: tree, modelVersion: stamp),
        read('expected.docspecs.yaml'));
  });

  test('YAML decode→memory→encode is byte-stable and preserves the stamp', () {
    final golden = read('expected.docspecs.yaml');
    final decoded = SpecDocumentYaml.decode(golden, tree);
    expect(decoded.modelVersion, stamp);
    expect(
        SpecDocumentYaml.encode(
            document: decoded.document, tree: tree, modelVersion: stamp),
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

  // Plan item #9: the Markdown route must land a fixture document in the *same*
  // shared memory representation as the canonical state — not merely re-export
  // byte-stably. Parsing `expected.md` and applying it must reproduce
  // `state.json` (the YAML-route memory) exactly, proving both formats converge
  // on one in-memory document (§4.1 "both routes land in the same memory
  // representation"). Every language port asserts the same against this corpus.
  test('Markdown route lands in the shared memory representation', () {
    final golden = read('expected.md');
    final canonical = jsonDecode(read('state.json')) as Map<String, dynamic>;
    final parsed = SpecDocumentMarkdown(model, doc).parse(golden);
    expect(parsed.rejections, isEmpty, reason: parsed.rejections.join('\n'));
    final landed = SpecDocument()
      ..loadJson({
        'content': parsed.content,
        'forms': parsed.forms,
        'lists': parsed.lists,
      });
    expect(landed.toJson(), canonical,
        reason: 'Markdown→memory must equal the canonical state.json memory');
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

  // AA1 criteria 3–6: two-letter-date encoding, list-item id generation
  // (within-day numbering), same-day reuse on last-item deletion, and unique-id
  // enforcement on override. Pinned as a language-agnostic corpus file so every
  // port reproduces the identical id semantics.
  test('section-id cases match the committed expectations', () {
    final cases =
        jsonDecode(read('section_id_cases.json')) as Map<String, dynamic>;

    // Criterion 4: the two-letter day code.
    for (final c in (cases['twoLetterDate'] as List).cast<Map>()) {
      final date = DateTime(2026, c['month'] as int, c['day'] as int);
      expect(encodeTwoLetterDate(date), c['expect'],
          reason: 'twoLetterDate ${c['month']}/${c['day']}');
    }

    // Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
    for (final c in (cases['generate'] as List).cast<Map>()) {
      final date = DateTime(2026, c['month'] as int, c['day'] as int);
      final existing = (c['existing'] as List).cast<String>();
      expect(generateListItemSectionId(c['pattern'] as String, date, existing),
          c['expect'],
          reason: 'generate ${c['pattern']} over $existing');
    }

    // Criteria 5 & 6 at the document level: override keeps ids unique, deleting
    // the last same-day item frees its number for reuse, deleting a middle one
    // never renumbers the rest.
    final d = SpecDocument();
    for (final s in (cases['documentOps'] as List).cast<Map>()) {
      switch (s['op']) {
        case 'addGen':
          final date = DateTime(2026, s['month'] as int, s['day'] as int);
          final id = generateListItemSectionId(s['pattern'] as String, date,
              d.listItemSectionIds(s['listPath'] as String));
          expect(id, s['expectId'], reason: 'addGen id');
          final path =
              d.addListItem(s['listPath'] as String, sectionId: id);
          expect(path, s['expectPath'], reason: 'addGen path');
        case 'sectionIds':
          expect(d.listItemSectionIds(s['listPath'] as String),
              (s['expect'] as List).cast<String>());
        case 'removeListItem':
          expect(d.removeListItem(s['itemPath'] as String), s['expect']);
        case 'override':
          d.setItemSectionId(s['itemPath'] as String, s['id'] as String);
        case 'overrideThrows':
          expect(
              () => d.setItemSectionId(s['itemPath'] as String, s['id'] as String),
              throwsA(isA<SpecSectionIdCollision>()));
        case 'addExplicitThrows':
          expect(
              () => d.addListItem(s['listPath'] as String, sectionId: s['id'] as String),
              throwsA(isA<SpecSectionIdCollision>()));
        default:
          fail('unknown section-id op ${s['op']}');
      }
    }
  });

  // AA1 criterion 7: members serialize in @SerializationOrder, not alphabetical.
  test('serialization-order case matches the committed expectations', () {
    final c = jsonDecode(read('serialization_order_cases.json'))
        as Map<String, dynamic>;
    final orderModel = SpecModel.fromJson(c['model'] as Map<String, dynamic>);
    final order = SpecSerializationOrder(orderModel);
    expect(order.orderPaths((c['contentPaths'] as List).cast<String>()),
        (c['expectedOrder'] as List).cast<String>());
    expect(
        order.orderFormFields(
            c['formPath'] as String, (c['formFields'] as List).cast<String>()),
        (c['expectedFormOrder'] as List).cast<String>());
  });
}

// --- Fixture construction (the reference data the corpus is generated from) --

/// A compact, hand-authored meta-model that still exercises every field kind:
/// content (incl. a multi-line block-scalar value), enum, scalar, a two-field
/// `@Form`, a `@Min`-constrained complex list, a nested complex section, and a
/// (declared-but-unpopulated) scalar list for resolution coverage.
///
/// All members carry field-level `@SectionId`s (so the Markdown golden heads
/// every section per the DR3 transparency rule) **except** `Item.label`, which
/// is deliberately id-less: it pins the transparent-member semantics — its text
/// is the item heading's body region, bound at `<item>/label` without a
/// heading of its own.
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
            {
              'name': 'title',
              'kind': 'content',
              'sectionId': 'TTL',
              'contentType': 'text'
            },
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'SUM',
              'contentType': 'markdown'
            },
            {
              'name': 'priority',
              'kind': 'enum',
              'sectionId': 'PRI',
              'enumType': 'Priority',
              'enumValues': ['low', 'high'],
            },
            {'name': 'count', 'kind': 'scalar', 'sectionId': 'CNT', 'type': 'int'},
            {
              'name': 'details',
              'kind': 'form',
              'sectionId': 'DET',
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
            {
              'name': 'meta',
              'kind': 'complex',
              'sectionId': 'META',
              'type': 'Meta'
            },
          ],
        },
        'Item': {
          'name': 'Item',
          'fields': [
            // Deliberately id-less: the transparent body-region member.
            {'name': 'label', 'kind': 'content'},
            {
              'name': 'status',
              'kind': 'enum',
              'sectionId': 'STS',
              'enumType': 'Status',
              'enumValues': ['open', 'done'],
            },
          ],
        },
        'Meta': {
          'name': 'Meta',
          'fields': [
            {'name': 'owner', 'kind': 'content', 'sectionId': 'OWNR'},
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
  d.setContent('DEMO/TTL', 'Hello');
  d.setContent('DEMO/SUM', 'Line one\nLine two\n\nLine four');
  d.setContent('DEMO/PRI', 'high');
  d.setContent('DEMO/CNT', '3');
  d.setFormField('DEMO/DET', 'owner', 'Bob');
  d.setFormField('DEMO/DET', 'contact', 'bob@example.com');
  final i1 = d.addListItem('DEMO/items');
  d.setContent('$i1/label', 'First');
  d.setContent('$i1/STS', 'open');
  final i2 = d.addListItem('DEMO/items');
  d.setContent('$i2/label', 'Second line A\nwith ```triple``` ticks');
  d.setContent('$i2/STS', 'done');
  d.setContent('DEMO/META/OWNR', 'alice');
  // Scalar list exercising the YAML 1.1-special quoting rule (DR1 §2.5, DRC6):
  // `on`/`no` are 1.1-only booleans and `1:30` is a 1.1 sexagesimal int — all
  // three parse as plain strings under YAML 1.2 (Dart) but as bool/number under
  // YAML 1.1 (PyYAML). The emitter must quote them so every runtime reads back
  // the exact string. `plain` proves an ordinary scalar still emits plainly.
  final tags = ['on', 'no', '1:30', 'plain'];
  for (final tag in tags) {
    final t = d.addListItem('DEMO/META/tags');
    d.setContent(t, tag);
  }
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
    'DEMO/TTL',
    'DEMO/SUM',
    'DEMO/PRI',
    'DEMO/CNT',
    'DEMO/DET',
    'DEMO/items',
    'DEMO/items-1',
    'DEMO/items-1/label',
    'DEMO/items-1/STS',
    'DEMO/META',
    'DEMO/META/OWNR',
    'DEMO/META/tags',
    'DEMO/META/tags-1',
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
        'DEMO/DET': {'bogus': 'v'}
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

/// The section-id corpus (AA1 criteria 3–6). `twoLetterDate` and `generate` pin
/// the two pure algorithms; `documentOps` replays the document-level id
/// semantics (unique-override, same-day reuse on last-item delete, no-renumber
/// on middle delete). Dates use the fixed year 2026 (year is irrelevant to the
/// two-letter code). Generated ids use the pattern `DEMO-ITEM-xxx` on 4 March
/// (`C` = month 3, `D` = day 4 → day code `CD`).
Map<String, dynamic> _sectionIdCases() => {
      'twoLetterDate': [
        {'month': 1, 'day': 1, 'expect': 'AA'},
        {'month': 1, 'day': 26, 'expect': 'AZ'},
        {'month': 1, 'day': 27, 'expect': 'A0'},
        {'month': 1, 'day': 31, 'expect': 'A4'},
        {'month': 2, 'day': 1, 'expect': 'BA'},
        {'month': 6, 'day': 15, 'expect': 'FO'},
        {'month': 10, 'day': 10, 'expect': 'JJ'},
        {'month': 12, 'day': 26, 'expect': 'LZ'},
        {'month': 12, 'day': 27, 'expect': 'L0'},
        {'month': 12, 'day': 31, 'expect': 'L4'},
      ],
      'generate': [
        {
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'existing': <String>[],
          'expect': 'DEMO-ITEM-CD1'
        },
        {
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'existing': <String>['DEMO-ITEM-CD1'],
          'expect': 'DEMO-ITEM-CD2'
        },
        // Middle deleted (CD2 gone): max is still 3, so the next id is CD4 —
        // numbering stays non-consecutive, nothing is renumbered.
        {
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'existing': <String>['DEMO-ITEM-CD1', 'DEMO-ITEM-CD3'],
          'expect': 'DEMO-ITEM-CD4'
        },
        // A different day starts its own numbering, ignoring other days' ids.
        {
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 5,
          'existing': <String>['DEMO-ITEM-CD1', 'DEMO-ITEM-CD2'],
          'expect': 'DEMO-ITEM-CE1'
        },
        {
          'pattern': 'CUOPME-OPER-xxx',
          'month': 12,
          'day': 31,
          'existing': <String>[],
          'expect': 'CUOPME-OPER-L41'
        },
      ],
      'documentOps': <Map<String, dynamic>>[
        {
          'op': 'addGen',
          'listPath': 'DEMO/items',
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'expectId': 'DEMO-ITEM-CD1',
          'expectPath': 'DEMO/items-1'
        },
        {
          'op': 'addGen',
          'listPath': 'DEMO/items',
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'expectId': 'DEMO-ITEM-CD2',
          'expectPath': 'DEMO/items-2'
        },
        {
          'op': 'addGen',
          'listPath': 'DEMO/items',
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'expectId': 'DEMO-ITEM-CD3',
          'expectPath': 'DEMO/items-3'
        },
        {
          'op': 'sectionIds',
          'listPath': 'DEMO/items',
          'expect': ['DEMO-ITEM-CD1', 'DEMO-ITEM-CD2', 'DEMO-ITEM-CD3']
        },
        // Delete the MIDDLE item (CD2): the others keep their ids …
        {'op': 'removeListItem', 'itemPath': 'DEMO/items-2', 'expect': true},
        {
          'op': 'sectionIds',
          'listPath': 'DEMO/items',
          'expect': ['DEMO-ITEM-CD1', 'DEMO-ITEM-CD3']
        },
        // … and a new same-day item takes CD4 (not the freed CD2): no renumber.
        {
          'op': 'addGen',
          'listPath': 'DEMO/items',
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'expectId': 'DEMO-ITEM-CD4',
          'expectPath': 'DEMO/items-4'
        },
        // Delete the LAST item (CD4) …
        {'op': 'removeListItem', 'itemPath': 'DEMO/items-4', 'expect': true},
        // … a new same-day item REUSES CD4 (criterion 6, same-day reuse).
        {
          'op': 'addGen',
          'listPath': 'DEMO/items',
          'pattern': 'DEMO-ITEM-xxx',
          'month': 3,
          'day': 4,
          'expectId': 'DEMO-ITEM-CD4',
          'expectPath': 'DEMO/items-5'
        },
        // Criterion 5: an arbitrary override is accepted …
        {
          'op': 'override',
          'itemPath': 'DEMO/items-5',
          'id': 'DEMO-ITEM-CUSTOM'
        },
        {
          'op': 'sectionIds',
          'listPath': 'DEMO/items',
          'expect': ['DEMO-ITEM-CD1', 'DEMO-ITEM-CD3', 'DEMO-ITEM-CUSTOM']
        },
        // … but a colliding override is rejected …
        {
          'op': 'overrideThrows',
          'itemPath': 'DEMO/items-1',
          'id': 'DEMO-ITEM-CUSTOM'
        },
        // … as is adding an explicit id that already exists in the list.
        {
          'op': 'addExplicitThrows',
          'listPath': 'DEMO/items',
          'id': 'DEMO-ITEM-CD1'
        },
      ],
    };

/// The serialization-order corpus (AA1 criterion 7). A small model whose fields
/// declare `@SerializationOrder` in reverse-alphabetical order, so a correct
/// emission (ZETA, MID, ALPHA) is visibly different from the alphabetical
/// default. Form fields follow their declared order (title before author).
/// Expected results are computed live so `UPDATE_CORPUS` keeps them honest.
Map<String, dynamic> _serializationOrderCase() {
  final meta = <String, dynamic>{
    'metaSchemaVersion': 1,
    'modelVersion': 1,
    'roots': [
      {'type': 'Root', 'title': 'Demo', 'sectionId': 'DEMO'}
    ],
    'classes': {
      'Root': {
        'name': 'Root',
        'sectionId': 'DEMO',
        'fields': [
          {
            'name': 'head',
            'kind': 'form',
            'sectionId': 'HEAD',
            'serializationOrder': 0,
            'formFields': [
              {'name': 'title', 'label': 'Title', 'type': 'String'},
              {'name': 'author', 'label': 'Author', 'type': 'String'},
            ],
          },
          {
            'name': 'zeta',
            'kind': 'content',
            'sectionId': 'ZETA',
            'serializationOrder': 1
          },
          {
            'name': 'mid',
            'kind': 'content',
            'sectionId': 'MID',
            'serializationOrder': 2
          },
          {
            'name': 'alpha',
            'kind': 'content',
            'sectionId': 'ALPHA',
            'serializationOrder': 3
          },
        ],
      },
    },
  };
  final model = SpecModel.fromJson(meta);
  final order = SpecSerializationOrder(model);
  const contentPaths = ['DEMO/ALPHA', 'DEMO/MID', 'DEMO/ZETA'];
  const formFields = ['author', 'title'];
  return {
    'model': meta,
    'contentPaths': contentPaths,
    'expectedOrder': order.orderPaths(contentPaths),
    'formPath': 'DEMO/HEAD',
    'formFields': formFields,
    'expectedFormOrder': order.orderFormFields('DEMO/HEAD', formFields),
  };
}
