/// Conformance harness for the **language-agnostic** spec-runtime corpus
/// (`../tom_som_conformance/corpus`, som_multiplatform_spec_model.md §19).
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
  final editorCases = _editorScript();
  final sectionIdCases = _sectionIdCases();
  final serializationOrderCase = _serializationOrderCase();
  final stampCases = _stampCases();
  final editabilityCases = _editabilityCases();
  final markdownImportCases = _markdownImportCases();
  final docSpecsCases = _docSpecsCases();
  final patternCases = _patternCases();
  final queryCases = _queryCases(model, doc);
  final projectionCases = _projectionCases(model, doc);
  final codeSpecsExtractCases = _codeSpecsExtractCases(model, doc);
  final cursorScript = _cursorScript(model);
  final nodeCreationCases = _nodeCreationCases(model);
  final nodeCreationScript = _nodeCreationScript(model);

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
    write('editor_cases.json', '${enc.convert(editorCases)}\n');
    write('section_id_cases.json', '${enc.convert(sectionIdCases)}\n');
    write('serialization_order_cases.json',
        '${enc.convert(serializationOrderCase)}\n');
    write('stamp_cases.json', '${enc.convert(stampCases)}\n');
    write('editability_cases.json', '${enc.convert(editabilityCases)}\n');
    write('markdown_import_cases.json',
        '${enc.convert(markdownImportCases)}\n');
    write('docspecs_schema.yaml', _docSpecsSchemaYaml);
    write('docspecs_cases.json', '${enc.convert(docSpecsCases)}\n');
    write('pattern_cases.json', '${enc.convert(patternCases)}\n');
    write('query_cases.json', '${enc.convert(queryCases)}\n');
    write('projection_cases.json', '${enc.convert(projectionCases)}\n');
    write('codespecs_extract_cases.json',
        '${enc.convert(codeSpecsExtractCases)}\n');
    write('cursor_cases.json', '${enc.convert(cursorScript)}\n');
    write('node_creation_cases.json', '${enc.convert(nodeCreationCases)}\n');
    write('node_creation_script.json',
        '${enc.convert(nodeCreationScript)}\n');
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

  test('model.meta.json carries the generation stamp the exporter writes', () {
    final reloaded =
        SpecModel.fromJson(jsonDecode(read('model.meta.json')) as Map<String, dynamic>);
    expect(reloaded.generatedAt, DateTime.utc(2026, 7, 20, 8));
    expect(reloaded.metaSchemaVersion, 1);
    // The counts are the payload's real sizes — that is what makes them a
    // self-check rather than a second, drift-prone declaration.
    expect(reloaded.classCount, reloaded.classes.length);
    expect(reloaded.rootCount, reloaded.roots.length);
    expect(reloaded.checkStamp().countsDisagree, isFalse);
    // The synthetic fixture declares no container class.
    expect(reloaded.containerRoot, isNull);
  });

  group('stamp_cases.json (the cross-language stamp contract)', () {
    // Declared, not deferred: one test per case needs the table at declaration
    // time. Under UPDATE_CORPUS the committed file may not exist yet (setUpAll
    // has not run), so the freshly built table stands in for that one run.
    final onDisk = File('${corpusDir.path}/stamp_cases.json');
    final table = update && !onDisk.existsSync()
        ? stampCases
        : jsonDecode(onDisk.readAsStringSync()) as Map<String, dynamic>;

    test('the default threshold matches the runtime constant', () {
      expect(table['defaultMaxAgeDays'], defaultMaxSnapshotAge.inDays);
    });

    for (final raw in table['cases'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        final loaded =
            SpecModel.fromJson(c['model'] as Map<String, dynamic>);
        final want = c['expect'] as Map<String, dynamic>;
        expect(loaded.generatedAt?.millisecondsSinceEpoch,
            _secondsToMillis(want['generatedAtEpochSeconds'] as int?));
        expect(loaded.metaSchemaVersion, want['metaSchemaVersion']);
        expect(loaded.classCount, want['classCount']);
        expect(loaded.rootCount, want['rootCount']);
        expect(loaded.containerRoot, want['containerRoot']);
        expect(loaded.classes.length, want['actualClassCount']);
        expect(loaded.roots.length, want['actualRootCount']);

        final wantCheck = c['check'] as Map<String, dynamic>;
        final got = loaded.checkStamp(
          now: DateTime.fromMillisecondsSinceEpoch(
              (wantCheck['nowEpochSeconds'] as int) * 1000,
              isUtc: true),
          maxAge: Duration(days: wantCheck['maxAgeDays'] as int),
        );
        expect(got.age?.inSeconds, wantCheck['ageSeconds']);
        expect(got.isAged, wantCheck['isAged']);
        expect(got.classCountDisagrees, wantCheck['classCountDisagrees']);
        expect(got.rootCountDisagrees, wantCheck['rootCountDisagrees']);
        expect(got.countsDisagree, wantCheck['countsDisagree']);
        expect(got.isStale, wantCheck['isStale']);
        expect(got.warnings, wantCheck['warnings']);
      });
    }
  });

  group('editability_cases.json (the §4.2/§21 version contract)', () {
    final onDisk = File('${corpusDir.path}/editability_cases.json');
    final table = update && !onDisk.existsSync()
        ? editabilityCases
        : jsonDecode(onDisk.readAsStringSync()) as Map<String, dynamic>;

    for (final raw in table['cases'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        final generated = c['generated'] as String;
        final documentVersion = c['documentVersion'] as String?;

        expect(somEditabilityFor(generated, documentVersion).name,
            c['editability']);

        // The classifier and the check are one rule seen twice: `rejects` is
        // just "the classification is not editable", so asserting both here is
        // what makes a port that classifies right and throws wrong fail.
        if (c['rejects'] as bool) {
          expect(
              () => checkSomModelVersion(generated, documentVersion),
              throwsA(isA<SomVersionException>()
                  .having((e) => e.message, 'message', c['message'])));
        } else {
          expect(() => checkSomModelVersion(generated, documentVersion),
              returnsNormally);
          expect(c['message'], isNull);
        }
      });
    }
  });

  // SOM §11.7: a Markdown import never silently drops a block. Every case
  // asserts the rejection report *and* what still landed — see
  // `_markdownImportCases` for why neither half is sufficient alone.
  group('markdown_import_cases.json (the §11.7 rejection protocol)', () {
    final onDisk = File('${corpusDir.path}/markdown_import_cases.json');
    final table = update && !onDisk.existsSync()
        ? markdownImportCases
        : jsonDecode(onDisk.readAsStringSync()) as Map<String, dynamic>;

    for (final raw in table['cases'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        // Parsing is document-independent (headline staging compares against
        // the *schema* default, never against the target document), so a fresh
        // document keeps every case reproducible in isolation.
        final parsed =
            SpecDocumentMarkdown(model, SpecDocument()).parse(c['markdown'] as String);

        final got = [
          for (final r in parsed.rejections)
            {
              'line': r.line,
              'reason': r.reason.name,
              'anchor': r.anchor,
              'message': r.message,
            }
        ];
        expect(got, c['rejections'],
            reason: 'rejection report must match §11.7 exactly, in order');

        final landed = SpecDocument()
          ..loadJson({
            'content': parsed.content,
            'forms': parsed.forms,
            'lists': parsed.lists,
            'headlines': parsed.headlines,
          });
        expect(landed.toJson(), c['document'],
            reason: 'the blocks that were not rejected must still land');
      });
    }
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
        'headlines': parsed.headlines,
      });
    expect(SpecDocumentMarkdown(model, reDoc).exportRoot(model.roots.first),
        golden);
  });

  // `som_multiplatform_spec_model.md` §11: the Markdown route must land a
  // fixture document in the *same* shared memory representation as the
  // canonical state — not merely re-export
  // byte-stably. Parsing `expected.md` and applying it must reproduce
  // `state.json` (the YAML-route memory) exactly, proving both formats converge
  // on one in-memory document (SOM §8 "both routes land in the same memory
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
        'headlines': parsed.headlines,
      });
    expect(landed.toJson(), canonical,
        reason: 'Markdown→memory must equal the canonical state.json memory');
  });

  // SOM §11.2 list-container contract (DRA1/DRA2): every list heads its own
  // container section — a real `*-LST` `@SectionId` when the list carries one
  // (`REF-LST`), else the member-name fallback (`items`, `tags`) — with an
  // empty body region and its numbered items exactly one level deeper. Pinned
  // against the committed golden so every language port reproduces the identical
  // container structure.
  group('list-container structure (SOM §11.2)', () {
    final md = read('expected.md');
    final lines = md.split('\n');

    int levelAt(int idx) => RegExp(r'^(#+)\s')
        .firstMatch(lines[idx])!
        .group(1)!
        .length;

    int headingIndexOf(String id) {
      final idx = lines.indexWhere((l) => l.contains('<!--[$id]-->'));
      expect(idx, greaterThanOrEqualTo(0),
          reason: 'heading <!--[$id]--> is present in the golden');
      return idx;
    }

    /// Asserts [containerId] heads a list container whose body is empty (every
    /// line up to the next heading is blank) and whose [itemIds] each head
    /// exactly one level below it.
    void expectContainer(String containerId, List<String> itemIds) {
      final ci = headingIndexOf(containerId);
      final containerLevel = levelAt(ci);
      var j = ci + 1;
      while (j < lines.length &&
          !SpecDocumentMarkdown.headingLine.hasMatch(lines[j])) {
        expect(lines[j].trim(), isEmpty,
            reason: 'container <!--[$containerId]--> must carry no body of its '
                'own (offending line ${j + 1}: "${lines[j]}")');
        j++;
      }
      expect(j, lessThan(lines.length),
          reason: 'container <!--[$containerId]--> has at least one item');
      expect(levelAt(j), containerLevel + 1,
          reason: 'the first item heads one level below its container');
      for (final itemId in itemIds) {
        expect(levelAt(headingIndexOf(itemId)), containerLevel + 1,
            reason: 'item <!--[$itemId]--> heads one level below its container');
      }
    }

    test('a `*-LST` list heads under its @SectionId, empty-bodied, items deeper',
        () {
      // Item 1 carries the stored id `REF-SPEC` (YRD3); item 2 is anonymous.
      expectContainer('REF-LST', ['REF-SPEC', 'REF-2']);
      // Card 1 carries the stored id `CARD-ALPHA` (YRD3); card 2 falls back to
      // the pattern (`CARD-2`).
      expectContainer('CARD-LST', ['CARD-ALPHA', 'CARD-2']);
    });

    test('id-less lists head under the member-name container, empty-bodied', () {
      expectContainer('items', ['items-1', 'items-2']);
      expectContainer('tags', ['tags-1', 'tags-2', 'tags-3', 'tags-4']);
    });

    test('md round-trips through the container (item values + empty body)', () {
      final parsed = SpecDocumentMarkdown(model, doc).parse(md);
      expect(parsed.rejections, isEmpty, reason: parsed.rejections.join('\n'));
      final reDoc = SpecDocument()
        ..loadJson({
          'content': parsed.content,
          'forms': parsed.forms,
          'lists': parsed.lists,
          'headlines': parsed.headlines,
        });
      expect(reDoc.listItems('DEMO/REF-LST'),
          ['DEMO/REF-LST-1', 'DEMO/REF-LST-2']);
      expect(reDoc.itemSectionId('DEMO/REF-LST-1'), 'REF-SPEC',
          reason: 'a stored item id round-trips through md (YRD3)');
      expect(reDoc.headline('DEMO/REF-LST-1'), 'Reference to the Spec',
          reason: 'a stored item headline round-trips through md (YRD3)');
      expect(reDoc.content('DEMO/REF-LST-1'), 'spec §1.2');
      expect(reDoc.content('DEMO/REF-LST-2'), 'ADR7');
      expect(reDoc.content('DEMO/REF-LST'), isNull,
          reason: 'the container carries no body content of its own');
    });
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

  // The guard that every `SpecValidationCode` has a case here — and the same
  // guard for every other nine-language enumeration — lives in
  // `enum_coverage_test.dart`. It used to be written out at this spot, was
  // copied once for the DocSpecs tier, and is now one shared mechanism.

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
        case 'setHeadline':
          d.setHeadline(s['path'] as String, s['value'] as String);
        case 'headline':
          expect(d.headline(s['path'] as String), s['expect']);
        default:
          fail('unknown op ${s['op']}');
      }
    }
  });

  // YRD7: the generic, meta-validated modification API (SpecEditor) — typed
  // value/form-field round-trips through the shared boundary helpers, enum
  // domain validation, and structural create/clear ops.
  // Executed against the corpus model, so every language's generic editor
  // replays the identical script.
  test('editor script replays with the committed results', () {
    final steps = jsonDecode(read('editor_cases.json')) as List;
    final d = SpecDocument();
    final ed = SpecEditor.forModel(d, model);
    for (final s in steps.cast<Map<String, dynamic>>()) {
      switch (s['op']) {
        case 'setValue':
          ed.setValue(s['path'] as String, s['value']);
        case 'value':
          expect(ed.value(s['path'] as String), s['expect'],
              reason: 'value ${s['path']}');
        case 'valueThrows':
          expect(() => ed.value(s['path'] as String), throwsArgumentError,
              reason: 'valueThrows ${s['path']}');
        case 'setValueThrows':
          expect(() => ed.setValue(s['path'] as String, s['value']),
              throwsArgumentError,
              reason: 'setValueThrows ${s['path']}');
        case 'setContent': // raw store write (bypasses the typed boundary)
          d.setContent(s['path'] as String, s['value'] as String);
        case 'rawContent':
          expect(d.content(s['path'] as String), s['expect'],
              reason: 'rawContent ${s['path']}');
        case 'setFormValue':
          ed.setFormValue(s['path'] as String, s['field'] as String, s['value']);
        case 'formValue':
          expect(ed.formValue(s['path'] as String, s['field'] as String),
              s['expect'],
              reason: 'formValue ${s['path']}#${s['field']}');
        case 'formValueThrows':
          expect(
              () => ed.formValue(s['path'] as String, s['field'] as String),
              throwsArgumentError,
              reason: 'formValueThrows ${s['path']}#${s['field']}');
        case 'setFormValueThrows':
          expect(
              () => ed.setFormValue(
                  s['path'] as String, s['field'] as String, s['value']),
              throwsArgumentError,
              reason: 'setFormValueThrows ${s['path']}#${s['field']}');
        case 'rawFormField':
          expect(d.formField(s['path'] as String, s['field'] as String),
              s['expect'],
              reason: 'rawFormField ${s['path']}#${s['field']}');
        case 'formFieldNames':
          expect(
              ed.formFields(s['path'] as String).map((f) => f.name).toList(),
              s['expect'],
              reason: 'formFieldNames ${s['path']}');
        case 'formFieldNamesThrows':
          expect(() => ed.formFields(s['path'] as String), throwsArgumentError,
              reason: 'formFieldNamesThrows ${s['path']}');
        case 'setHeadline':
          ed.setHeadline(s['path'] as String, s['value'] as String?);
        case 'headline':
          expect(ed.headline(s['path'] as String), s['expect'],
              reason: 'headline ${s['path']}');
        case 'headlineThrows':
          expect(() => ed.headline(s['path'] as String), throwsArgumentError,
              reason: 'headlineThrows ${s['path']}');
        case 'itemSectionId':
          expect(d.itemSectionId(s['itemPath'] as String), s['expect'],
              reason: 'itemSectionId ${s['itemPath']}');
        case 'addListItem':
          final now = DateTime(2026, s['month'] as int, s['day'] as int);
          final p = ed.addListItem(s['listPath'] as String, now: now);
          expect(p, s['expectPath'], reason: 'addListItem ${s['listPath']}');
          if (s.containsKey('expectId')) {
            expect(d.itemSectionId(p), s['expectId'],
                reason: 'addListItem generated id ${s['listPath']}');
          }
        case 'addListItemThrows':
          final now = DateTime(2026, s['month'] as int, s['day'] as int);
          expect(() => ed.addListItem(s['listPath'] as String, now: now),
              throwsArgumentError,
              reason: 'addListItemThrows ${s['listPath']}');
        case 'removeListItem':
          expect(ed.removeListItem(s['itemPath'] as String), s['expect'],
              reason: 'removeListItem ${s['itemPath']}');
        case 'clearSection':
          ed.clearSection(s['path'] as String);
        case 'clearSectionThrows':
          expect(() => ed.clearSection(s['path'] as String),
              throwsArgumentError,
              reason: 'clearSectionThrows ${s['path']}');
        case 'hasValuesUnder':
          expect(d.hasValuesUnder(s['prefix'] as String), s['expect'],
              reason: 'hasValuesUnder ${s['prefix']}');
        default:
          fail('unknown editor op ${s['op']}');
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

  group('docspecs_cases.json (the SOM §14 DocSpecs tier)', () {
    DocSpecsValidator committedValidator() =>
        DocSpecsValidator(DocSpecsSchema.fromYamlText(
            read('docspecs_schema.yaml')));

    List<Map<String, dynamic>> committedCases() =>
        (jsonDecode(read('docspecs_cases.json')) as List)
            .cast<Map<String, dynamic>>();

    test('the committed schema loads with no unsupported features', () {
      // The schema is a corpus *input*: if a port's loader drops a feature the
      // cases depend on, the case expectations below would pass vacuously. So
      // pin the load itself — root id, warning-freedom, and the four features
      // the cases exercise beyond the plain section tree.
      final schema =
          DocSpecsSchema.fromYamlText(read('docspecs_schema.yaml'));
      expect(schema.warnings, isEmpty);
      expect(schema.rootSectionId, 'D00');
      expect(schema.sectionTypesByName['gsum']!.maxTextLength, 20);
      expect(schema.sectionTypesByName['d00-ovr']!.textRequired, isTrue);
      expect(schema.sectionTypesByName['steps']!.subsectionTypes['step']!
          .minCount, 2);
      expect(schema.formTypes['header-form']!.fields.first.required, isTrue);
    });

    test('cases match the committed rule/sectionId/line expectations', () {
      final validator = committedValidator();
      for (final c in committedCases()) {
        final got = validator
            .validateMarkdown(c['markdown'] as String)
            .map((v) => {
                  'rule': v.rule.name,
                  'sectionId': v.sectionId,
                  'line': v.line,
                })
            .toList();
        expect(got, c['violations'], reason: 'docspecs ${c['name']}');
      }
    });

    // Before this table existed the §14 golden read three lines off a *valid*
    // sample — root id, 0 warnings, 0 violations — so all eleven rules were
    // unexercised and the nine goldens agreed byte-for-byte about a question
    // none of them had been asked. That every rule now has a case is enforced
    // by `enum_coverage_test.dart`, together with every other nine-language
    // enumeration.
  });

  // -------------------------------------------------------------------------
  // spec_text_pattern / spec_query / spec_node_creation (SOM §9)
  // -------------------------------------------------------------------------

  group('pattern_cases.json (the portable pattern subset)', () {
    test('every committed case reproduces', () {
      final cases = (jsonDecode(read('pattern_cases.json')) as List)
          .cast<Map<String, dynamic>>();
      for (final c in cases) {
        final source = c['pattern'] as String;
        final regex = c['regex'] as bool;
        final ci = c['caseInsensitive'] as bool? ?? false;
        if (c['error'] == true) {
          expect(() => SomTextPattern.compile(source),
              throwsA(isA<SomPatternError>()),
              reason: 'pattern "$source" must be rejected');
          continue;
        }
        final p = regex
            ? SomTextPattern.compile(source, caseInsensitive: ci)
            : SomTextPattern.literal(source, caseInsensitive: ci);
        final got = [
          for (final s in p.allMatches(c['text'] as String)) [s.start, s.end],
        ];
        expect(got, c['spans'],
            reason: 'pattern "$source" over "${c['text']}"');
      }
    });

    test('the table exercises both compile outcomes', () {
      // A table of matches alone would let a port accept everything; a table of
      // rejections alone would let one reject everything.
      final cases = (jsonDecode(read('pattern_cases.json')) as List)
          .cast<Map<String, dynamic>>();
      expect(cases.where((c) => c['error'] == true), isNotEmpty);
      expect(cases.where((c) => c['error'] != true), isNotEmpty);
    });
  });

  group('query_cases.json (the spec_query surface)', () {
    test('every committed query reproduces its match list in order', () {
      final engine = SpecQueryEngine(model: model, document: doc);
      final cases = (jsonDecode(read('query_cases.json')) as List)
          .cast<Map<String, dynamic>>();
      for (final c in cases) {
        final cursor = engine.query(_queryFromJson(
            (c['query'] as Map).cast<String, dynamic>()));
        final got = [
          for (final m in cursor.toList())
            {
              'path': m.path,
              'kind': m.kind.name,
              'classId': m.classId,
              'headline': m.headline,
              'snippet': m.snippet,
              'spans': [
                for (final s in m.matchSpans) [s.start, s.end],
              ],
            },
        ];
        expect(got, c['matches'], reason: 'query ${c['name']}');
      }
    });

    test('count agrees with the committed match list', () {
      // The same fact from the other side: a port that implements `toList` by
      // draining but `count` by returning the candidate count passes the test
      // above and fails this one.
      final engine = SpecQueryEngine(model: model, document: doc);
      final cases = (jsonDecode(read('query_cases.json')) as List)
          .cast<Map<String, dynamic>>();
      for (final c in cases) {
        final cursor = engine.query(_queryFromJson(
            (c['query'] as Map).cast<String, dynamic>()));
        expect(cursor.count, (c['matches'] as List).length,
            reason: 'count for ${c['name']}');
      }
    });
  });

  test('projection_cases.json reproduces the structural walk', () {
    final engine = SpecQueryEngine(model: model, document: doc);
    final got = [
      for (final p in engine.projectNodes())
        {
          'path': p.path,
          'kind': p.kind.name,
          'classId': p.classId,
          'sectionId': p.sectionId,
          'mapsTo': p.mapsTo,
          'detailedIn': p.detailedIn,
          'headline': p.headline,
          'searchableStrings': p.searchableStrings,
          'hasValue': p.hasValue,
        },
    ];
    expect(got, jsonDecode(read('projection_cases.json')));
  });

  group('codespecs_extract_cases.json (the Phase-4 extract generator)', () {
    // Declared, not deferred: the error and root cases need one test each at
    // declaration time. Under UPDATE_CORPUS the committed file is whatever the
    // last run left — it may not exist, and when a case is added it is stale by
    // definition — so the freshly built table stands in for that one run; the
    // ordinary run that follows is what verifies the committed file.
    final onDisk = File('${corpusDir.path}/codespecs_extract_cases.json');
    final table = update
        ? codeSpecsExtractCases
        : jsonDecode(onDisk.readAsStringSync()) as Map<String, dynamic>;

    final extractor = CodeSpecsExtractor(
      model: model,
      document: doc,
      catalog: CodeSpecsAreaCatalog.fromJson(
          (table['catalog'] as Map).cast<String, dynamic>()),
    );

    test('the routing verdicts reproduce the committed diagnostic', () {
      final got = [
        for (final r in extractor.routings())
          {
            'path': r.path,
            'className': r.className,
            'verdict': r.verdict.name,
            'values': r.values,
            'note': r.note,
            'declaredAt': r.declaredAt,
          },
      ];
      expect(got, table['routings']);
    });

    test('the extracts reproduce the committed goldens byte for byte', () {
      final got = [
        for (final x in extractor.extractAll())
          {
            'area': x.area.code,
            'canonicalId': x.area.canonicalId,
            'part': x.area.kindValue,
            'documentRoot': x.documentRoot,
            'fileStem': x.fileStem,
            'projects': x.projects,
            'citableParts': x.citableParts,
            'entries': [
              for (final e in x.entries)
                {
                  'sectionId': e.sectionId,
                  'headline': e.headline,
                  'instanceId': e.instanceId,
                  'path': e.path,
                  'className': e.className,
                  'fieldName': e.fieldName,
                  'formField': e.formField,
                  'routedBy': e.routedBy,
                  'routedAt': e.routedAt,
                  'routingNote': e.routingNote,
                  'value': e.value,
                },
            ],
            'yaml': x.toYaml(),
            'markdown': x.toMarkdown(),
          },
      ];
      expect(got, table['extracts']);
    });

    test('every emitted value occurs verbatim in the source document', () {
      // The guard `codespecs_derivation_contract.md` §2.8 C1 rests on, carried
      // in the corpus rather than left to each port's own conscience: the
      // generator may copy and index, it may not compose. Membership, not
      // substring — that is what makes "verbatim" mean verbatim rather than
      // "derived from".
      final stored = <String>{
        ...(state['content'] as Map).values.cast<String>(),
        for (final section in (state['forms'] as Map).values)
          ...(section as Map).values.cast<String>(),
      };
      expect(stored, isNotEmpty);
      for (final x in (table['extracts'] as List).cast<Map<String, dynamic>>()) {
        for (final e in (x['entries'] as List).cast<Map<String, dynamic>>()) {
          expect(stored, contains(e['value']),
              reason: '${x['area']} ${e['path']} was not copied from the '
                  'document');
        }
      }
    });

    test('a @FollowUpKind subtree contributes to no extract', () {
      // `Control` is populated, and populated distinctively, so its absence
      // cannot be an accident of an empty section.
      final emitted = <String>[
        for (final x in (table['extracts'] as List).cast<Map<String, dynamic>>())
          for (final e in (x['entries'] as List).cast<Map<String, dynamic>>())
            e['value'] as String,
      ];
      expect(emitted, isNot(contains('Controlled summary')));
      expect(emitted, isNot(contains('ctrl-owner')));
      // …and neither does a @NoArtifact section's own leaf.
      expect(emitted, isNot(contains('alice')));
    });

    for (final raw in (table['errorCases'] as List).cast<Map<String, dynamic>>()) {
      final c = raw;
      test(c['name'] as String, () {
        final errModel =
            SpecModel.fromJson((c['model'] as Map).cast<String, dynamic>());
        // The error case carries its own model and state rather than mutating
        // the shared fixture: `model.meta.json` is a VALID model by
        // construction (§10.2 `ROUTE-TOTAL` holds over it), and a port in a
        // language without cheap structural editing should not have to break it
        // to run this case. `state` is the ordinary `state.json` shape, so
        // every runtime already has the loader.
        final errDoc = SpecDocument()
          ..loadJson((c['state'] as Map).cast<String, dynamic>());
        final errExtractor = CodeSpecsExtractor(
          model: errModel,
          document: errDoc,
          catalog: CodeSpecsAreaCatalog.fromJson(
              (table['catalog'] as Map).cast<String, dynamic>()),
        );
        final want = (c['expect'] as Map).cast<String, dynamic>();
        expect(
          () => errExtractor.extractAll(),
          throwsA(isA<CodeSpecsExtractError>()
              .having((e) => e.path, 'path', want['path'])
              .having((e) => e.className, 'className', want['className'])
              .having((e) => e.message, 'message',
                  contains(want['messageContains']))),
        );
        expect(
          errExtractor
              .routings()
              .where((r) => r.path == want['path'])
              .map((r) => r.verdict.name),
          [want['routingVerdict']],
        );
      });
    }

    for (final c in (table['rootCases'] as List).cast<Map<String, dynamic>>()) {
      test('root scoping: ${c['name']}', () {
        final catalog = CodeSpecsAreaCatalog.fromJson(
            (table['catalog'] as Map).cast<String, dynamic>());
        final rootModel =
            SpecModel.fromJson((c['model'] as Map).cast<String, dynamic>());
        final rootDoc = SpecDocument()
          ..loadJson((c['state'] as Map).cast<String, dynamic>());
        final want = (c['expect'] as Map).cast<String, dynamic>();
        CodeSpecsExtractor build() => CodeSpecsExtractor(
              model: rootModel,
              document: rootDoc,
              catalog: catalog,
              rootType: c['rootType'] as String?,
            );
        if (want['fails'] == true) {
          expect(
            build,
            throwsA(isA<CodeSpecsExtractError>()
                .having((e) => e.path, 'path', want['path'])
                .having((e) => e.className, 'className', want['className'])
                .having((e) => e.message, 'message',
                    contains(want['messageContains']))),
          );
          return;
        }
        final x = build();
        expect(x.root.type, want['root']);
        expect(
          [for (final r in x.routings()) r.verdict.name],
          want['routingVerdicts'],
        );
        final extracts = x.extractAll();
        expect(extracts.first.documentRoot, want['documentRoot']);
        expect(
          [for (final e in extracts) ...e.entries.map((n) => n.path)],
          want['paths'],
        );
      });
    }
  });

  test('cursor script replays with the committed results', () {
    final steps = (jsonDecode(read('cursor_cases.json')) as List)
        .cast<Map<String, dynamic>>();
    final d = _buildDocument();
    final engine = SpecQueryEngine(model: model, document: d);
    SpecQueryCursor? cursor;
    for (final s in steps) {
      switch (s['op']) {
        case 'open':
          cursor = engine.query(
              _queryFromJson((s['query'] as Map).cast<String, dynamic>()));
        case 'count':
          expect(cursor!.count, s['expect'], reason: 'cursor count');
        case 'take':
          expect(cursor!.take(s['n'] as int).map((m) => m.path).toList(),
              s['expect'],
              reason: 'cursor take ${s['n']}');
        case 'next':
          expect(cursor!.next()?.path, s['expect'], reason: 'cursor next');
        case 'toList':
          expect(cursor!.toList().map((m) => m.path).toList(), s['expect'],
              reason: 'cursor toList');
        case 'removeListItem':
          d.removeListItem(s['itemPath'] as String);
        default:
          fail('unknown cursor op ${s['op']}');
      }
    }
  });

  test('node_creation_cases.json reproduces every gate decision', () {
    final cases = (jsonDecode(read('node_creation_cases.json')) as List)
        .cast<Map<String, dynamic>>();
    for (final c in cases) {
      final d = _buildDocument();
      final err = checkAddNode(model, d, c['parentPath'] as String,
          c['childSegment'] as String,
          itemId: c['itemId'] as String?);
      expect(err == null, c['accepted'], reason: 'accepted ${c['name']}');
      if (err != null) {
        expect(err.code.name, c['code'], reason: 'code ${c['name']}');
        expect(err.parentPath, c['parentPath']);
        expect(err.childSegment, c['childSegment']);
      }
    }
  });

  test('node-creation script replays with the committed results', () {
    final steps = (jsonDecode(read('node_creation_script.json')) as List)
        .cast<Map<String, dynamic>>();
    final d = _buildDocument();
    final creator = SpecNodeCreator(model, d);
    for (final s in steps) {
      switch (s['op']) {
        case 'add':
          final path = creator.add(
              s['parentPath'] as String, s['childSegment'] as String,
              itemId: s['itemId'] as String?,
              date: DateTime(2026, s['month'] as int, s['day'] as int));
          expect(path, s['expectPath'],
              reason: 'add ${s['parentPath']}/${s['childSegment']}');
          expect(d.itemSectionId(path), s['expectId'],
              reason: 'add id ${s['parentPath']}/${s['childSegment']}');
        case 'addThrows':
          expect(
              () => creator.add(
                  s['parentPath'] as String, s['childSegment'] as String,
                  itemId: s['itemId'] as String?, date: DateTime(2026, 3, 4)),
              throwsA(isA<SpecCreationError>()
                  .having((e) => e.code.name, 'code', s['expectCode'])),
              reason: 'addThrows ${s['parentPath']}/${s['childSegment']}');
        case 'finalState':
          expect(d.toJson(), s['expect'], reason: 'final document state');
        default:
          fail('unknown node-creation op ${s['op']}');
      }
    }
  });
}

/// Rebuilds a [SpecQuery] from its corpus wire form.
///
/// Every port needs this same decode, so its shape *is* part of the contract:
/// an absent key means "dimension unset", never a default that happens to
/// match. Kept beside the replay tests rather than in `lib/` because it belongs
/// to the corpus format, not to the runtime API.
SpecQuery _queryFromJson(Map<String, dynamic> j) => SpecQuery(
      text: j['text'] as String?,
      regex: j['regex'] as bool? ?? false,
      caseInsensitive: j['caseInsensitive'] as bool? ?? false,
      kinds: j['kinds'] == null
          ? null
          : {
              for (final k in (j['kinds'] as List).cast<String>())
                SpecNodeKind.values.firstWhere((v) => v.name == k),
            },
      className: j['className'] as String?,
      sectionIdExact: j['sectionIdExact'] as String?,
      sectionIdPrefix: j['sectionIdPrefix'] as String?,
      pathGlob: j['pathGlob'] as String?,
      mapsTo: j['mapsTo'] as String?,
      detailedIn: j['detailedIn'] as String?,
      state: j['state'] == null
          ? null
          : SpecStateFilter.values.firstWhere((v) => v.name == j['state']),
    );

// --- Fixture construction (the reference data the corpus is generated from) --

/// A SYNTHETIC codec-exerciser — NOT a model-convention reference.
///
/// This compact, hand-authored meta-model exists to exercise the codec's full
/// field-kind matrix across all nine language runtimes, so it deliberately
/// contains shapes that do NOT occur in the real `tom_specs_model` and must not
/// be read as conventions to imitate:
///   * `count`/`ratio`/`score` (kind `scalar`, types `int`/`double`/`num`) — the
///     real model has ZERO non-String primitive leaves. All three exist so the
///     typed boundary is exercised on a value LEAF and not only through a form
///     field: `SpecEditor` picks the converter in two independent places, so a
///     port can wire a type into one and forget the other;
///   * id-less `content` leaves (e.g. `Item.label`, `Control.owner`) — real
///     content leaves carry a field- or class-level `@SectionId`;
///   * `Control` — a class with TWO `content` leaves; real classes have exactly
///     one `content` body.
/// They exist only to force the codec down every branch (int scalar, id
/// fallback, transparent member, multi-content). For a convention-conformant
/// fixture, see the `realistic (convention-conformant) model` group in
/// `spec_document_yaml_test.dart`.
///
/// The kind coverage is **total**: all seven §7.1 field kinds are declared —
/// content (incl. a multi-line block-scalar value), enum, scalar, a two-field
/// `@Form`, a `@Min`-constrained complex list, a nested complex section, a
/// `section` member (`notes` → `Notes`), and a (declared-but-unpopulated)
/// scalar list for resolution coverage. Totality is not decoration: a kind no
/// case asks about is invisible rather than weakly covered, so eight ports
/// could disagree about it while the harness reports nine-way parity.
///
/// Both flavours of the SOM §11.2 `-LST` container rule are pinned: the `refs`
/// scalar list carries a real `@SectionId`/`@SectionIdPattern`, so its container
/// heads under `<!--[REF-LST]-->` with pattern items `<!--[REF-1]-->`; the
/// id-less `items`/`Meta.tags` lists head under the member-name fallback
/// (`<!--[items]-->`, `<!--[tags]-->`) with `<!--[items-1]-->`/`<!--[tags-1]-->`
/// items. Either way the container carries no body of its own (schema content
/// min/max-text-length 0).
///
/// All members carry field-level `@SectionId`s (so the Markdown golden heads
/// every section per the schema generator's transparency rule) **except** `Item.label`, which
/// is deliberately id-less: it pins the transparent-member semantics — its text
/// is the item heading's body region, bound at `<item>/label` without a
/// heading of its own.
Map<String, dynamic> _buildMeta() => {
      'metaSchemaVersion': 1,
      'modelVersion': 1,
      'modelVersionLabel': 'demo-1.0',
      // The generation stamp the exporter writes alongside the payload. Fixed
      // rather than `DateTime.now()` so the corpus is byte-stable; the counts
      // are the fixture's real sizes, which is what makes them a self-check.
      // `containerRoot` is deliberately absent: the fixture has no container
      // class, so declaring one would be a lie. The present-`containerRoot`
      // path is covered by `stamp_cases.json` instead.
      'generatedAt': '2026-07-20T08:00:00.000000Z',
      'classCount': 12,
      'rootCount': 2,
      'roots': [
        {
          'type': 'Demo',
          'title': 'Demo Document',
          'sectionId': 'DEMO',
          'description': 'A compact conformance fixture. SYNTHETIC codec-'
              'exerciser covering the full field-kind matrix (incl. an int '
              'scalar, id-less content leaves, and a dual-content class) — NOT '
              'a tom_specs_model convention reference.',
        },
        {
          // csrf3: a SECOND root exists so the fixture has two disjoint
          // reference scopes. The instance-tier reference check skips a
          // reference whose target registry the document's own root cannot
          // reach, and with a single root every registry is always reachable —
          // the skip would be unreachable code in all nine ports. This root
          // reaches no registry of its own, so a document rooted only here
          // must stay silent while the same reference fires from `Demo`.
          // It is deliberately never populated by `_buildDocument`, so the
          // md/yaml goldens are untouched by its existence.
          'type': 'Sidecar',
          'title': 'Sidecar Document',
          'sectionId': 'SIDE',
          'description': 'A second root reaching no registry — the fixture\'s '
              'cross-document reference scope (csrf3).',
        },
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
            // The §8.3 routing verdict. Every class in this fixture carries
            // exactly one of the three (`@CodeSpecKind` / `@FollowUpKind` /
            // `@NoArtifact`) except `Sidecar`, which is a bare `@Document` root
            // and structurally exempt — that is what makes the fixture a VALID
            // model under `tom_specs_model_rules.md` §10.2 `ROUTE-TOTAL`, and
            // what lets `codespecs_extract_cases.json` run against the shared
            // model rather than carrying an inline one.
            //
            // `Demo` is deliberately MULTI-VALUED: the same leaf must appear,
            // whole and undeduplicated, in both areas' extracts.
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.form', 'CodeSpecPart.viewState'],
                'note': 'the demo capture screen and its view state',
              }
            },
          ],
          'fields': [
            {
              'name': 'title',
              'kind': 'content',
              'sectionId': 'TTL',
              'contentType': 'text',
              // YRD4: field-level @Headline default — rendered because TTL
              // has no stored headline.
              'headline': 'Document Title',
            },
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'SUM',
              'contentType': 'markdown',
              // YRD4: default is shadowed by the stored 'Executive Summary'
              // headline — stored always wins.
              'headline': 'Summary',
            },
            {
              'name': 'priority',
              'kind': 'enum',
              'sectionId': 'PRI',
              'enumType': 'Priority',
              'enumValues': ['low', 'high'],
              // A FIELD-LEVEL `@CodeSpecKind`, overriding `Demo`'s class-level
              // one for this member alone: PRI reaches `navigation` and neither
              // of the class's two areas. Without a case, a port that only ever
              // reads the class annotation passes.
              'annotations': [
                {
                  'name': 'CodeSpecKind',
                  'arguments': {
                    'kinds': ['CodeSpecPart.navigation'],
                  }
                }
              ],
            },
            {
              'name': 'count',
              'kind': 'scalar',
              'sectionId': 'CNT',
              'type': 'int',
              // The fixture's one *field* doc comment. Headline resolution
              // falls back stored -> field doc -> class doc -> root
              // description, and with no field carrying a doc the second step
              // was unreachable. CNT has no stored headline, so this is what
              // its headline resolves to.
              'doc': 'How many items are tracked.',
            },
            {
              // The `double` half of the numeric matrix as a CONTENT LEAF, not
              // just a form field. `Details.weight` already exercises the
              // double conversion through the form store, but the leaf path
              // runs a different dispatch (`value`/`setValue` on a scalar
              // node), and the rule that discriminates a single-numeric-type
              // port — an integral double formats as `2.0`, never `2` — has to
              // hold on both.
              'name': 'ratio',
              'kind': 'scalar',
              'sectionId': 'RTO',
              'type': 'double',
            },
            {
              // `num` — the one conversion family in `spec_typed_values` that
              // no member of this fixture used to declare, so `somParseNum` /
              // `somFormatNum` were implemented nine times and asked nothing.
              // It is the family most likely to diverge, because it is the one
              // whose formatting depends on the *runtime value*: an integral
              // num writes `7`, a fractional one `7.5`, from the same field.
              'name': 'score',
              'kind': 'scalar',
              'sectionId': 'SCR',
              'type': 'num',
            },
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
                // YRD7: typed form fields — stored as plain text
                // (`FieldName: value`), converted at the type boundary by the
                // shared somParse*/somFormat* helpers, natively typed in the
                // generic editor and the generated facades.
                {'name': 'estimate', 'label': 'Estimate', 'type': 'int'},
                {'name': 'weight', 'label': 'Weight', 'type': 'double'},
                // The form half of the `num` family. The leaf half is
                // `Demo.score`; both exist because the editor dispatches on
                // type in two independent places (`value`/`formValue`), so a
                // port that wires `num` into one and forgets the other passes
                // a single-sided corpus.
                {'name': 'tally', 'label': 'Tally', 'type': 'num'},
                {'name': 'active', 'label': 'Active', 'type': 'bool'},
                {
                  'name': 'priority',
                  'label': 'Priority',
                  'type': 'Priority',
                  'enumValues': ['low', 'high'],
                },
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
              // A genuine `*-LST` list: the container heads under its own
              // `@SectionId` (`REF-LST`, a real `*-LST` id) and the items
              // resolve against the `@SectionIdPattern` (`REF-xxx` → `REF-1`,
              // `REF-2`). Kept scalar so it pins the container contract without a
              // new element class; contrasts with the id-less `Meta.tags` list.
              'name': 'refs',
              'kind': 'list',
              'sectionId': 'REF-LST',
              'sectionIdPattern': 'REF-xxx',
              'elementType': 'String',
              'elementIsComplex': false,
            },
            {
              // A `*-LST` list of complex items whose own transparent
              // `content` form carries an ordinary `note` field. Item ids and
              // headlines are stored directly in the YRD3 stores (card 1 sets
              // `CARD-ALPHA` + a headline; card 2 falls back to defaults).
              'name': 'cards',
              'kind': 'list',
              'sectionId': 'CARD-LST',
              'sectionIdPattern': 'CARD-xxx',
              'elementType': 'Card',
              'elementIsComplex': true,
            },
            {
              'name': 'meta',
              'kind': 'complex',
              'sectionId': 'META',
              'type': 'Meta'
            },
            {
              // A class-level-only `@SectionId`: the `control` field itself has
              // NO id, so its key resolves to the TARGET CLASS's id — the SOM
              // SOM §12.2 field-id-else-class-id fallback (YR01). Pins that a
              // section/complex node heads under `CTRL control:` (yaml) /
              // `<!--[CTRL]-->` (markdown) even without a field id, while its
              // leaves keep field-level (or bare) content keys.
              'name': 'control',
              'kind': 'complex',
              'type': 'Control'
            },
            {
              // The §7.1 `section` kind — the seventh structural kind, and the
              // one nothing else in the fixture declares. It matters more than
              // its rarity suggests: `section` COLLAPSES into its target class
              // exactly as `complex` does, so a port that classifies it as a
              // leaf misresolves every path beneath it, and a port that omits
              // it from the `sectionId ?? classSectionId` key rule (SOM §12.2)
              // mis-keys the whole subtree.
              //
              // Deliberately id-less with a class-level `@SectionId` (`NOTE`),
              // mirroring `control` above: that pins the class-id fallback for
              // the *section* half of the section/complex rule, which `control`
              // pins only for the complex half. Both halves now have a case, so
              // a codec written for `complex` alone fails here rather than
              // shipping.
              'name': 'notes',
              'kind': 'section',
              'type': 'Notes'
            },
            {
              // csrf3: the two instance-tier checks — cross-registry
              // references and `@OneOf`/`@Case` selection — need model
              // constructs nothing else in this fixture uses. They live under
              // one member so the rest of the matrix above reads unchanged,
              // and `_buildDocument` never populates it, so the md/yaml
              // goldens are unaffected; the validation cases build their own
              // states.
              'name': 'registry',
              'kind': 'complex',
              'sectionId': 'REG',
              'type': 'Registry'
            },
          ],
        },
        // csrf3: the reference/one-of fixture. `RegistryEntry` is the
        // registry — it declares ids in a form field (`RGE.code`) AND through
        // its own list-item section ids (the reserved `RGE.@sectionId` slot) —
        // and `RegistryLink` is the referrer, with one field per target shape:
        // a plain form-field target, the reserved slot, and a two-registry
        // disjunction that also carries a comma-separated multi-value.
        'Registry': {
          'name': 'Registry',
          'sectionId': 'REG',
          'annotations': [
            {
              'name': 'SectionId',
              'arguments': {'id': 'REG'}
            },
            // `container` — the walk must DESCEND into it (its children carry
            // their own verdicts) while contributing nothing of its own.
            {
              'name': 'NoArtifact',
              'arguments': {'reason': 'NoArtifactReason.container'}
            },
          ],
          'fields': [
            {
              'name': 'entries',
              'kind': 'list',
              'sectionId': 'RGE-LST',
              'sectionIdPattern': 'RGE-xxx',
              'elementType': 'RegistryEntry',
              'elementIsComplex': true,
            },
            {
              'name': 'links',
              'kind': 'list',
              'sectionId': 'RGL-LST',
              'sectionIdPattern': 'RGL-xxx',
              'elementType': 'RegistryLink',
              'elementIsComplex': true,
            },
            {
              'name': 'choice',
              'kind': 'complex',
              'sectionId': 'CHO',
              'type': 'Choice'
            },
          ],
        },
        'RegistryEntry': {
          'name': 'RegistryEntry',
          'sectionId': 'RGE',
          'annotations': [
            {
              'name': 'SectionId',
              'arguments': {'id': 'RGE'}
            },
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.dataAccess'],
              }
            },
          ],
          'fields': [
            {
              'name': 'details',
              'kind': 'form',
              'sectionId': 'RGE-DET',
              'formFields': [
                {'name': 'code', 'label': 'Code', 'type': 'String'},
                {'name': 'label', 'label': 'Label', 'type': 'String'},
              ],
            },
          ],
        },
        'RegistryLink': {
          'name': 'RegistryLink',
          'sectionId': 'RGL',
          'annotations': [
            {
              'name': 'SectionId',
              'arguments': {'id': 'RGL'}
            },
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.dataAccess'],
              }
            },
          ],
          'fields': [
            {
              'name': 'details',
              'kind': 'form',
              'sectionId': 'RGL-DET',
              'formFields': [
                {
                  'name': 'entryCode',
                  'label': 'Entry Code',
                  'type': 'String',
                  'refersTo': ['RGE.code'],
                },
                {
                  'name': 'entryId',
                  'label': 'Entry Id',
                  'type': 'String',
                  'refersTo': ['RGE.@sectionId'],
                },
                {
                  // A disjunction: the value may name a `code` OR an item
                  // section id, and a comma-separated value resolves segment
                  // by segment.
                  'name': 'anyRefs',
                  'label': 'Any Refs',
                  'type': 'String',
                  'refersTo': ['RGE.code', 'RGE.@sectionId'],
                },
              ],
            },
          ],
        },
        'Choice': {
          'name': 'Choice',
          'sectionId': 'CHO',
          'annotations': [
            {
              'name': 'SectionId',
              'arguments': {'id': 'CHO'}
            },
            {
              'name': 'OneOf',
              'arguments': {'discriminator': 'kind'}
            },
            {
              'name': 'NoArtifact',
              'arguments': {'reason': 'NoArtifactReason.container'}
            },
          ],
          'fields': [
            {
              'name': 'selector',
              'kind': 'form',
              'sectionId': 'CHO-SEL',
              'formFields': [
                {
                  'name': 'kind',
                  'label': 'Kind',
                  'type': 'ChoiceKind',
                  'enumValues': ['alpha', 'beta'],
                },
              ],
            },
            // Two subsections for `alpha` — so the "more than one populated
            // subsection for the chosen case" branch is reachable — one for
            // `beta`, and one common subsection carrying no `@Case` at all,
            // which is legal under every choice.
            {
              'name': 'alphaPart',
              'kind': 'complex',
              'sectionId': 'CHO-ALP',
              'type': 'ChoicePart',
              'annotations': [
                {
                  'name': 'Case',
                  'arguments': {'value': 'ChoiceKind.alpha'}
                }
              ],
            },
            {
              'name': 'alphaExtra',
              'kind': 'complex',
              'sectionId': 'CHO-AL2',
              'type': 'ChoicePart',
              'annotations': [
                {
                  'name': 'Case',
                  'arguments': {'value': 'ChoiceKind.alpha'}
                }
              ],
            },
            {
              'name': 'betaPart',
              'kind': 'complex',
              'sectionId': 'CHO-BET',
              'type': 'ChoicePart',
              'annotations': [
                {
                  'name': 'Case',
                  'arguments': {'value': 'ChoiceKind.beta'}
                }
              ],
            },
            {
              'name': 'commonPart',
              'kind': 'complex',
              'sectionId': 'CHO-COM',
              'type': 'ChoicePart'
            },
          ],
        },
        'ChoicePart': {
          'name': 'ChoicePart',
          'annotations': [
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.text'],
              }
            },
          ],
          'fields': [
            {'name': 'note', 'kind': 'content'},
          ],
        },
        'Sidecar': {
          'name': 'Sidecar',
          'sectionId': 'SIDE',
          // Deliberately carries NO routing verdict: a bare `@Document` root is
          // structurally exempt from `ROUTE-TOTAL` (a root is the document, not
          // a section of it). It is the fixture's only unannotated class, so a
          // port that treats "no verdict" as an unconditional hard error fails
          // here rather than only on a real specification.
          'annotations': [
            {
              'name': 'Document',
              'arguments': {'title': 'Sidecar Document'}
            },
            {
              'name': 'SectionId',
              'arguments': {'id': 'SIDE'}
            },
          ],
          'fields': [
            {
              // Refers into `Demo`'s registry, which this root does NOT reach —
              // the cross-document case the instance tier must pass over.
              'name': 'details',
              'kind': 'form',
              'sectionId': 'SIDE-DET',
              'formFields': [
                {
                  'name': 'entryCode',
                  'label': 'Entry Code',
                  'type': 'String',
                  'refersTo': ['RGE.code'],
                },
              ],
            },
          ],
        },
        'Control': {
          'name': 'Control',
          'sectionId': 'CTRL',
          'annotations': [
            {
              'name': 'SectionId',
              'arguments': {'id': 'CTRL'}
            },
            // The fixture's `@FollowUpKind` subtree. `Control` is POPULATED by
            // `_buildDocument` ('Controlled summary' / 'ctrl-owner'), so its
            // absence from every extract is an assertion rather than an
            // accident of an empty section.
            {
              'name': 'FollowUpKind',
              'arguments': {
                'processes': ['FollowUpProcess.doc'],
                'note': 'delivered as operator documentation, not as code',
              }
            },
          ],
          'fields': [
            // `summary` keeps a field-level content key (`CTRL-SUM summary:`);
            // `owner` is id-less and keeps a bare content key (`owner:`).
            {'name': 'summary', 'kind': 'content', 'sectionId': 'CTRL-SUM'},
            {'name': 'owner', 'kind': 'content'},
          ],
        },
        // The target of `Demo.notes`, the fixture's one `section`-kind member.
        // Kept to a single content leaf on purpose: what the case has to pin is
        // the KIND — that a section collapses and keys on its class id — not a
        // new leaf shape. Its own id (`NOTE`) is what the id-less `notes` member
        // falls back to.
        'Notes': {
          'name': 'Notes',
          'sectionId': 'NOTE',
          'annotations': [
            {
              'name': 'SectionId',
              'arguments': {'id': 'NOTE'}
            },
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.text'],
              }
            },
          ],
          'fields': [
            {'name': 'body', 'kind': 'content', 'sectionId': 'NOTE-BDY'},
          ],
        },
        'Item': {
          'name': 'Item',
          // YRD4: class-level @Headline default — drives the item title stem
          // ('Task 1', 'Task 2') instead of itemTitleStem('Item').
          'headline': 'Task',
          'annotations': [
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.form'],
              }
            },
          ],
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
        'Card': {
          'name': 'Card',
          // The fixture's one carrier of the traceability annotations and of a
          // class doc comment. Without them the `mapsTo`/`detailedIn` query
          // filters could only ever be pinned as "matches nothing", which a
          // runtime that never implemented them satisfies just as well as one
          // that did, and the doc-comment branch of headline resolution would
          // never be reached. Card is the right carrier: nothing else reads
          // these three (no md, docspecs or reflection golden mentions them),
          // so they discriminate the query surface without moving anything
          // else.
          'mapsTo': 'CS00-CARD',
          'detailedIn': 'BP00-CARDS',
          'doc': 'A card entry.',
          'annotations': [
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.viewState'],
              }
            },
          ],
          'fields': [
            {
              // The section's OWN form (transparent, id-less `content` member).
              'name': 'content',
              'kind': 'form',
              'formFields': [
                {'name': 'note', 'label': 'Note', 'type': 'String'},
              ],
            },
          ],
        },
        'Meta': {
          'name': 'Meta',
          // The second `@NoArtifact` reason, and the one whose suppression is
          // OBSERVABLE: unlike `Registry`/`Choice`, `Meta` is populated
          // ('alice', the four tags), so a port that emits an unrouted class's
          // own leaves fails here.
          'annotations': [
            {
              'name': 'NoArtifact',
              'arguments': {'reason': 'NoArtifactReason.overview'}
            },
          ],
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
  // The *populate* order here is deliberately neither the model's declaration
  // order (owner, contact, estimate, weight, tally, active, priority) nor
  // alphabetical (active, contact, estimate, owner, priority, weight). Keeping
  // the three distinct is the fixture's only defence against a runtime that
  // emits a form in whatever order its store happens to hold: the md/yaml
  // goldens and `projection_cases.json` pin declaration order, `state.json`
  // pins alphabetical, and a port that iterates its store now agrees with
  // neither. When the three coincided, four ports read the store and passed.
  // See SOM §9, "Form-field order". Do not "tidy" this back into order.
  //
  // YRD7: typed form-field values in their canonical plain-text store form —
  // exactly the strings somFormatInt(8) / somFormatDouble(2.5) /
  // somFormatBool(true) / somFormatEnumName('high', …) produce, so the yaml/md
  // goldens pin the typed fields' serialization as ordinary `FieldName: value`.
  d.setFormField('DEMO/DET', 'priority', 'high');
  d.setFormField('DEMO/DET', 'weight', '2.5');
  d.setFormField('DEMO/DET', 'owner', 'Bob');
  d.setFormField('DEMO/DET', 'active', 'true');
  d.setFormField('DEMO/DET', 'estimate', '8');
  d.setFormField('DEMO/DET', 'contact', 'bob@example.com');
  // A form **preamble** — free text before the first field line (SOM §11.4
  // rule 7). It rides in the same `content` slot a plain section's body uses,
  // so this pins the one shape a form section has that a non-form section does
  // not: content and form values at the same path, in both codecs.
  //
  // The second line is deliberately label-shaped AND shadows DET's *declared*
  // `owner` field. That makes the rule-3 escape load-bearing across all nine
  // ports: a runtime that emits the preamble unescaped writes a line the
  // parser will read back as `owner: this line is prose, not the field.`,
  // silently overwriting `Bob` — a byte-stable export that loses a value.
  d.setContent('DEMO/DET',
      'Captured during the November review.\n'
      'Owner: this line is prose, not the field.');
  final i1 = d.addListItem('DEMO/items');
  d.setContent('$i1/label', 'First');
  d.setContent('$i1/STS', 'open');
  final i2 = d.addListItem('DEMO/items');
  d.setContent('$i2/label', 'Second line A\nwith ```triple``` ticks');
  d.setContent('$i2/STS', 'done');
  // A genuine `*-LST` list (id `REF-LST`, pattern `REF-xxx`): its container
  // heads under `<!--[REF-LST]-->` with `<!--[REF-1]-->` items one level below.
  for (final ref in ['spec §1.2', 'ADR7']) {
    final r = d.addListItem('DEMO/REF-LST');
    d.setContent(r, ref);
  }
  // YRD3 fixtures: stored headlines + a stored (pattern-shaped, non-numeric)
  // item section id must round-trip through md AND yaml byte-stably.
  //  * a renamed fixed-section headline on a content leaf (`SUM`);
  //  * a form-section headline (`DET`) and a list-container headline (`items`);
  //  * item 1 of `REF-LST` carries stored id `REF-SPEC` (parses back as a
  //    stored id — non-numeric, so position is recovered as "next item") plus
  //    a stored headline (a scalar item: yaml `{headline, content}` mapping).
  d.setHeadline('DEMO/SUM', 'Executive Summary');
  d.setHeadline('DEMO/DET', 'Details & Contacts');
  d.setHeadline('DEMO/items', 'Work Items');
  d.setItemSectionId('DEMO/REF-LST-1', 'REF-SPEC');
  d.setHeadline('DEMO/REF-LST-1', 'Reference to the Spec');
  // Card 1 gets a stored (pattern-shaped, non-numeric) item section id and a
  // stored headline (YRD3 stores). Card 2 keeps both defaults (`CARD-2`
  // heading id, derived item title). The ordinary `note` field lands in the
  // form store.
  final c1 = d.addListItem('DEMO/CARD-LST');
  d.setItemSectionId(c1, 'CARD-ALPHA');
  d.setHeadline(c1, 'Alpha Card');
  d.setFormField('$c1/content', 'note', 'first card');
  final c2 = d.addListItem('DEMO/CARD-LST');
  d.setFormField('$c2/content', 'note', 'second card');
  d.setContent('DEMO/META/OWNR', 'alice');
  // Scalar list exercising the YAML 1.1-special quoting rule (SOM §12.5):
  // `on`/`no` are 1.1-only booleans and `1:30` is a 1.1 sexagesimal int — all
  // three parse as plain strings under YAML 1.2 (Dart) but as bool/number under
  // YAML 1.1 (PyYAML). The emitter must quote them so every runtime reads back
  // the exact string. `plain` proves an ordinary scalar still emits plainly.
  final tags = ['on', 'no', '1:30', 'plain'];
  for (final tag in tags) {
    final t = d.addListItem('DEMO/META/tags');
    d.setContent(t, tag);
  }
  // A class-level-only section (`Control`, id `CTRL`): its container heads under
  // `CTRL control:` even though the `control` field has no id, while its leaves
  // keep their own content keys (`CTRL-SUM summary:` / bare `owner:`).
  d.setContent('DEMO/control/CTRL-SUM', 'Controlled summary');
  d.setContent('DEMO/control/owner', 'ctrl-owner');
  // The `section`-kind member (`Notes`, class id `NOTE`, id-less field). It is
  // POPULATED rather than declared-only so the md/yaml codecs are exercised on
  // a section node too: the resolver and the codecs are separate risks, and a
  // declared-but-empty member would have pinned only the first.
  d.setContent('DEMO/notes/NOTE-BDY', 'Section-kind body');
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
    // The `*-LST` container path and one of its positional items.
    'DEMO/REF-LST',
    'DEMO/REF-LST-1',
    // The card list container, one item, and its own (transparent
    // `content`) form node.
    'DEMO/CARD-LST',
    'DEMO/CARD-LST-1',
    'DEMO/CARD-LST-1/content',
    'DEMO/META',
    'DEMO/META/OWNR',
    'DEMO/META/tags',
    'DEMO/META/tags-1',
    // The class-level-only section and its two leaves (YR02).
    'DEMO/control',
    'DEMO/control/CTRL-SUM',
    'DEMO/control/owner',
    // The `section` kind (§7.1): the node itself, and one leaf BENEATH it —
    // the second case is the load-bearing one, because a port that fails to
    // collapse a section into its target class resolves the parent correctly
    // and everything under it not at all.
    'DEMO/notes',
    'DEMO/notes/NOTE-BDY',
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
    // The one non-leaf that may carry content: a form node, whose content is
    // the preamble (SOM §11.4 rule 7). Pinned as its own case rather than left
    // to ride on `valid`, because the two say different things — `valid` would
    // still pass if the exemption were widened to every non-leaf, and this case
    // sits directly beside the `kindMismatch` one that proves it was not.
    caseFor('formPreamble', {
      'content': {'DEMO/DET': 'free text above the fields'}
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
    // --- csrf3: the two instance-tier checks ------------------------------
    //
    // Every case below is rooted in `DEMO` unless it says otherwise, so the
    // registry `RGE` is in scope and the reference check actually decides.
    caseFor('referencesResolve', _registryState(
      entryCode: 'ALPHA',
      entryId: 'RGE-ALPHA',
      anyRefs: 'BETA, RGE-2',
    )),
    caseFor('danglingReference', _registryState(
      // One miss per target shape: an unknown `code`, an unknown item section
      // id, and a two-segment disjunction whose second segment resolves in
      // neither registry (the first still does, so exactly one error).
      entryCode: 'GAMMA',
      entryId: 'RGE-9',
      anyRefs: 'ALPHA, NOPE',
    )),
    // A reference is skipped, not reported, when the document's own root
    // cannot reach the target registry: `Sidecar` reaches no registry, so its
    // unresolvable reference is a cross-document one and stays silent.
    caseFor('crossDocumentReferenceSkipped', {
      'forms': {
        'SIDE/SIDE-DET': {'entryCode': 'NOT-A-CODE'}
      }
    }),
    // …but the skip is about *scope*, not about the field: the same document
    // that also populates `Demo` brings `RGE` into scope, and then it fires.
    caseFor('crossDocumentReferenceInScope', () {
      final state = _registryState(
        entryCode: 'ALPHA',
        entryId: 'RGE-ALPHA',
        anyRefs: 'ALPHA',
      );
      (state['forms'] as Map<String, Object?>)['SIDE/SIDE-DET'] = {
        'entryCode': 'NOT-A-CODE'
      };
      return state;
    }()),
    caseFor('oneOfCaseSelected', _choiceState('alpha', ['CHO-ALP', 'CHO-COM'])),
    // `beta` is populated while `alpha` is chosen — the common subsection is
    // always allowed and must not be reported alongside it.
    caseFor('oneOfCaseMismatch',
        _choiceState('alpha', ['CHO-BET', 'CHO-COM'])),
    // Two subsections bound to the *chosen* case: at most one may be present.
    caseFor('oneOfCaseAmbiguous',
        _choiceState('alpha', ['CHO-ALP', 'CHO-AL2'])),
  ];
}

/// A document state populating the csrf3 registry: two entries (item 1 with a
/// stored section id, item 2 anonymous so its id is positional) and one link
/// whose three reference fields carry [entryCode], [entryId] and [anyRefs].
Map<String, Object?> _registryState({
  required String entryCode,
  required String entryId,
  required String anyRefs,
}) =>
    {
      'forms': {
        'DEMO/REG/RGE-LST-1/RGE-DET': {'code': 'ALPHA', 'label': 'Alpha'},
        'DEMO/REG/RGE-LST-2/RGE-DET': {'code': 'BETA', 'label': 'Beta'},
        'DEMO/REG/RGL-LST-1/RGL-DET': {
          'entryCode': entryCode,
          'entryId': entryId,
          'anyRefs': anyRefs,
        },
      },
      'lists': {
        'DEMO/REG/RGE-LST': {
          'seq': 2,
          'items': ['DEMO/REG/RGE-LST-1', 'DEMO/REG/RGE-LST-2'],
          // Item 1 declares `RGE-ALPHA`; item 2 has no stored id, so its
          // effective id is the pattern with the position (`RGE-2`). Both
          // halves of the reserved `@sectionId` slot are therefore live.
          'ids': {'DEMO/REG/RGE-LST-1': 'RGE-ALPHA'},
        },
        'DEMO/REG/RGL-LST': {
          'seq': 1,
          'items': ['DEMO/REG/RGL-LST-1'],
        },
      },
    };

/// A document state choosing [kind] on the `@OneOf` container and populating
/// the subsections named by [populatedSectionIds].
Map<String, Object?> _choiceState(String kind, List<String> populatedSectionIds) => {
      'content': {
        for (final id in populatedSectionIds)
          'DEMO/REG/CHO/$id/note': 'body of $id',
      },
      'forms': {
        'DEMO/REG/CHO/CHO-SEL': {'kind': kind}
      },
    };

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
      // YRD3: stored headlines — set/read, empty-clears, purge on item removal.
      {'op': 'setHeadline', 'path': 'A/h', 'value': 'Custom Heading'},
      {'op': 'headline', 'path': 'A/h', 'expect': 'Custom Heading'},
      {'op': 'isEmpty', 'expect': false},
      {'op': 'setHeadline', 'path': 'A/h', 'value': ''},
      {'op': 'headline', 'path': 'A/h', 'expect': null},
      {'op': 'setHeadline', 'path': 'A/l-3/t', 'value': 'Item Heading'},
      {'op': 'headline', 'path': 'A/l-3/t', 'expect': 'Item Heading'},
      {'op': 'removeListItem', 'itemPath': 'A/l-3', 'expect': true},
      {'op': 'headline', 'path': 'A/l-3/t', 'expect': null},
    ];

/// The generic-editor corpus (YRD7): a scripted sequence of typed, meta-
/// validated modifications executed against the corpus model by every
/// language's generic editor. Values in `value`/`expect` are JSON-typed
/// (number / bool / string / null), so each runtime asserts the *native*
/// typed reading, while `rawContent`/`rawFormField` pin the underlying
/// plain-text store form (`FieldName: value`). Enum values travel as
/// constant-name strings at this generic layer; out-of-domain names and
/// dangling/non-leaf paths must raise the language's argument error — on the
/// READ side (`valueThrows`, `formValueThrows`, `formFieldNamesThrows`,
/// `headlineThrows`) as strictly as on the write side, because a port that
/// answers `null` for a path that does not exist is indistinguishable from a
/// correct one on every non-throwing case.
///
/// All five conversion families of `spec_typed_values` are exercised here:
/// `int` (`DEMO/CNT`, `Details.estimate`), `double` (`DEMO/RTO`,
/// `Details.weight`), `num` (`DEMO/SCR`, `Details.tally`), `bool`
/// (`Details.active`) and enum names (`DEMO/PRI`, `Details.priority`) — each
/// through BOTH dispatches, the value leaf and the form field, since a port
/// wires those separately.
List<Map<String, dynamic>> _editorScript() => [
      // --- typed value leaves ------------------------------------------------
      {'op': 'setValue', 'path': 'DEMO/CNT', 'value': 3},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': 3},
      {'op': 'rawContent', 'path': 'DEMO/CNT', 'expect': '3'},
      {'op': 'setValue', 'path': 'DEMO/CNT', 'value': null},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': null},
      {'op': 'rawContent', 'path': 'DEMO/CNT', 'expect': null},
      {'op': 'setValue', 'path': 'DEMO/CNT', 'value': '12'},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': 12},
      {'op': 'rawContent', 'path': 'DEMO/CNT', 'expect': '12'},
      {'op': 'setValueThrows', 'path': 'DEMO/CNT', 'value': true},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': 12},
      // Forgiving read: raw garbage in the store reads as null, not an error.
      {'op': 'setContent', 'path': 'DEMO/CNT', 'value': 'abc'},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': null},
      {'op': 'setContent', 'path': 'DEMO/CNT', 'value': ''},
      // `double` LEAF (DEMO/RTO). `Details.weight` already covers the double
      // conversion through the form store; this covers the other dispatch, and
      // pins the rule that separates a faithful port from one that leans on its
      // own number-to-string: an integral double writes `4.0`, never `4`.
      {'op': 'setValue', 'path': 'DEMO/RTO', 'value': 2.5},
      {'op': 'value', 'path': 'DEMO/RTO', 'expect': 2.5},
      {'op': 'rawContent', 'path': 'DEMO/RTO', 'expect': '2.5'},
      {'op': 'setValue', 'path': 'DEMO/RTO', 'value': 4},
      {'op': 'value', 'path': 'DEMO/RTO', 'expect': 4.0},
      {'op': 'rawContent', 'path': 'DEMO/RTO', 'expect': '4.0'},
      // A String passes through VERBATIM even into a typed leaf, so the store
      // keeps `6` — the formatter never runs. Reading it back still parses as a
      // double, so `value` and `rawContent` legitimately disagree here.
      {'op': 'setValue', 'path': 'DEMO/RTO', 'value': '6'},
      {'op': 'value', 'path': 'DEMO/RTO', 'expect': 6.0},
      {'op': 'rawContent', 'path': 'DEMO/RTO', 'expect': '6'},
      {'op': 'setValueThrows', 'path': 'DEMO/RTO', 'value': true},
      {'op': 'setContent', 'path': 'DEMO/RTO', 'value': 'abc'},
      {'op': 'value', 'path': 'DEMO/RTO', 'expect': null},
      {'op': 'setValue', 'path': 'DEMO/RTO', 'value': null},
      {'op': 'value', 'path': 'DEMO/RTO', 'expect': null},
      {'op': 'rawContent', 'path': 'DEMO/RTO', 'expect': null},
      // `num` LEAF (DEMO/SCR) — the family whose rendering depends on the
      // *value*, not the declared type: the same field writes `7` for an
      // integral value and `7.5` for a fractional one. That is the opposite of
      // the `double` rule directly above, which is why both have to be here:
      // a port that implements one formatter for "any number" fails exactly
      // one of these two blocks whichever way it chose.
      {'op': 'setValue', 'path': 'DEMO/SCR', 'value': 7},
      {'op': 'value', 'path': 'DEMO/SCR', 'expect': 7},
      {'op': 'rawContent', 'path': 'DEMO/SCR', 'expect': '7'},
      {'op': 'setValue', 'path': 'DEMO/SCR', 'value': 7.5},
      {'op': 'value', 'path': 'DEMO/SCR', 'expect': 7.5},
      {'op': 'rawContent', 'path': 'DEMO/SCR', 'expect': '7.5'},
      {'op': 'setValue', 'path': 'DEMO/SCR', 'value': '9'},
      {'op': 'value', 'path': 'DEMO/SCR', 'expect': 9},
      {'op': 'rawContent', 'path': 'DEMO/SCR', 'expect': '9'},
      {'op': 'setValueThrows', 'path': 'DEMO/SCR', 'value': true},
      {'op': 'setContent', 'path': 'DEMO/SCR', 'value': 'abc'},
      {'op': 'value', 'path': 'DEMO/SCR', 'expect': null},
      {'op': 'setValue', 'path': 'DEMO/SCR', 'value': null},
      {'op': 'rawContent', 'path': 'DEMO/SCR', 'expect': null},
      // Enum leaf: validated constant-name strings.
      {'op': 'setValue', 'path': 'DEMO/PRI', 'value': 'high'},
      {'op': 'value', 'path': 'DEMO/PRI', 'expect': 'high'},
      {'op': 'rawContent', 'path': 'DEMO/PRI', 'expect': 'high'},
      {'op': 'setValueThrows', 'path': 'DEMO/PRI', 'value': 'urgent'},
      {'op': 'setValueThrows', 'path': 'DEMO/PRI', 'value': 5},
      {'op': 'value', 'path': 'DEMO/PRI', 'expect': 'high'},
      {'op': 'setValue', 'path': 'DEMO/PRI', 'value': null},
      {'op': 'value', 'path': 'DEMO/PRI', 'expect': null},
      {'op': 'setContent', 'path': 'DEMO/PRI', 'value': 'urgent'},
      {'op': 'value', 'path': 'DEMO/PRI', 'expect': null},
      {'op': 'setContent', 'path': 'DEMO/PRI', 'value': ''},
      // Plain content leaf.
      {'op': 'setValue', 'path': 'DEMO/TTL', 'value': 'Hello'},
      {'op': 'value', 'path': 'DEMO/TTL', 'expect': 'Hello'},
      {'op': 'setValue', 'path': 'DEMO/TTL', 'value': ''},
      {'op': 'value', 'path': 'DEMO/TTL', 'expect': null},
      {'op': 'rawContent', 'path': 'DEMO/TTL', 'expect': null},
      // Strict resolution: dangling and non-leaf paths are rejected.
      {'op': 'setValueThrows', 'path': 'DEMO/ghost', 'value': 'x'},
      {'op': 'setValueThrows', 'path': 'DEMO/items', 'value': 'x'},
      {'op': 'setValueThrows', 'path': 'DEMO/META', 'value': 'x'},
      {'op': 'setValueThrows', 'path': 'DEMO/DET', 'value': 'x'},
      // The READ side of the same strictness. `value`/`formValue` resolve the
      // path exactly as their write siblings do, and a port that made reads
      // "forgiving" all the way down — returning null for a path that does not
      // exist — would pass every other case in this file, because a null read
      // is indistinguishable from an unset leaf. Only asking for the error
      // separates "no value here" from "no such place".
      {'op': 'valueThrows', 'path': 'DEMO/ghost'},
      {'op': 'valueThrows', 'path': 'DEMO/items'},
      {'op': 'valueThrows', 'path': 'DEMO/DET'},
      {'op': 'formFieldNames', 'path': 'DEMO/DET',
        'expect': ['owner', 'contact', 'estimate', 'weight', 'tally', 'active',
          'priority']},
      {'op': 'formFieldNamesThrows', 'path': 'DEMO/CNT'},
      {'op': 'formValueThrows', 'path': 'DEMO/ghost', 'field': 'owner'},
      {'op': 'formValueThrows', 'path': 'DEMO/CNT', 'field': 'owner'},
      {'op': 'formValueThrows', 'path': 'DEMO/DET', 'field': 'bogus'},
      // --- typed form fields (int / double / num / bool / enum) --------------
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'owner',
        'value': 'Bob'},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'owner',
        'expect': 'Bob'},
      {'op': 'setFormValueThrows', 'path': 'DEMO/DET', 'field': 'owner',
        'value': 5},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'owner',
        'expect': 'Bob'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'value': 8},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': 8},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': '8'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'value': '12'},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': 12},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': '12'},
      {'op': 'setFormValueThrows', 'path': 'DEMO/DET', 'field': 'estimate',
        'value': true},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'weight',
        'value': 2.5},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'weight',
        'expect': 2.5},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'weight',
        'expect': '2.5'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'weight', 'value': 2},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'weight', 'expect': 2.0},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'weight',
        'expect': '2.0'},
      // The `num` form field. Same family as `DEMO/SCR` above, different
      // dispatch: `formValue`/`setFormValue` pick the converter from the FORM
      // FIELD's declared type, not from a resolved model node, so the two are
      // separate code paths in every port.
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'tally', 'value': 3},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'tally', 'expect': 3},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'tally',
        'expect': '3'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'tally',
        'value': 3.25},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'tally',
        'expect': 3.25},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'tally',
        'expect': '3.25'},
      {'op': 'setFormValueThrows', 'path': 'DEMO/DET', 'field': 'tally',
        'value': true},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'tally',
        'value': null},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'tally',
        'expect': null},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'tally',
        'expect': null},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'active',
        'value': true},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'active',
        'expect': true},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'active',
        'expect': 'true'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'active',
        'value': false},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'active',
        'expect': false},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'active',
        'expect': 'false'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'priority',
        'value': 'high'},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'priority',
        'expect': 'high'},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'priority',
        'expect': 'high'},
      // Out-of-domain enum name and unknown field are rejected; null clears.
      {'op': 'setFormValueThrows', 'path': 'DEMO/DET', 'field': 'priority',
        'value': 'urgent'},
      {'op': 'setFormValueThrows', 'path': 'DEMO/DET', 'field': 'bogus',
        'value': 'x'},
      {'op': 'setFormValueThrows', 'path': 'DEMO/ghost', 'field': 'owner',
        'value': 'x'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'value': null},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': null},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': null},
      // Forgiving typed read of raw garbage in the form store.
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'active',
        'value': 'not-a-bool'},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'active',
        'expect': null},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'active',
        'expect': 'not-a-bool'},
      // --- structural ops: pattern id generation, clear ---------------------
      {'op': 'addListItem', 'listPath': 'DEMO/REF-LST', 'month': 3, 'day': 4,
        'expectPath': 'DEMO/REF-LST-1', 'expectId': 'REF-CD1'},
      {'op': 'itemSectionId', 'itemPath': 'DEMO/REF-LST-1',
        'expect': 'REF-CD1'},
      {'op': 'setValue', 'path': 'DEMO/REF-LST-1', 'value': 'spec §1.2'},
      {'op': 'value', 'path': 'DEMO/REF-LST-1', 'expect': 'spec §1.2'},
      {'op': 'addListItemThrows', 'listPath': 'DEMO/CNT', 'month': 3, 'day': 4},
      {'op': 'addListItem', 'listPath': 'DEMO/CARD-LST', 'month': 3, 'day': 4,
        'expectPath': 'DEMO/CARD-LST-1', 'expectId': 'CARD-CD1'},
      {'op': 'setFormValue', 'path': 'DEMO/CARD-LST-1/content',
        'field': 'note', 'value': 'first card'},
      // clearSection drops every value under a subtree; removeListItem drops
      // one item.
      {'op': 'setValue', 'path': 'DEMO/META/OWNR', 'value': 'alice'},
      {'op': 'setHeadline', 'path': 'DEMO/META', 'value': 'Metadata'},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/META', 'expect': true},
      {'op': 'clearSection', 'path': 'DEMO/META'},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/META', 'expect': false},
      {'op': 'rawContent', 'path': 'DEMO/META/OWNR', 'expect': null},
      {'op': 'headline', 'path': 'DEMO/META', 'expect': null},
      {'op': 'clearSectionThrows', 'path': 'DEMO/ghost'},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/CARD-LST-1', 'expect': true},
      {'op': 'removeListItem', 'itemPath': 'DEMO/CARD-LST-1', 'expect': true},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/CARD-LST-1', 'expect': false},
      {'op': 'removeListItem', 'itemPath': 'DEMO/CARD-LST-9', 'expect': false},
      // Headlines through the editor (resolution-checked).
      {'op': 'setHeadline', 'path': 'DEMO/SUM', 'value': 'Exec Summary'},
      {'op': 'headline', 'path': 'DEMO/SUM', 'expect': 'Exec Summary'},
      {'op': 'setHeadline', 'path': 'DEMO/SUM', 'value': ''},
      {'op': 'headline', 'path': 'DEMO/SUM', 'expect': null},
      {'op': 'headlineThrows', 'path': 'DEMO/ghost'},
    ];

int? _secondsToMillis(int? seconds) => seconds == null ? null : seconds * 1000;

/// The instant every stamp case is generated at: 2026-07-20T08:00:00Z.
const int _stampGeneratedAt = 1784534400;
const int _oneDay = 86400;

/// One generation-stamp case: a complete (minimal) model JSON, the five stamp
/// values it must decode to, and the verdict `checkStamp` must reach at a fixed
/// instant. Expectations are hand-written literals, not runtime output, so a
/// language that agrees with the table agrees with the *contract* rather than
/// merely with itself.
Map<String, dynamic> _stampCase({
  required String name,
  required Map<String, dynamic> stamp,
  int classes = 2,
  int roots = 1,
  required int nowEpochSeconds,
  int maxAgeDays = 14,
  int? ageSeconds,
  required bool isAged,
  bool classCountDisagrees = false,
  bool rootCountDisagrees = false,
  List<String> warnings = const [],
  int? generatedAtEpochSeconds,
}) {
  final countsDisagree = classCountDisagrees || rootCountDisagrees;
  return {
    'name': name,
    'model': {
      ...stamp,
      'roots': [
        for (var i = 0; i < roots; i++)
          {'type': 'R$i', 'title': 'Root $i'}
      ],
      'classes': {
        for (var i = 0; i < classes; i++)
          'C$i': {'name': 'C$i', 'fields': <dynamic>[]}
      },
    },
    'expect': {
      'generatedAtEpochSeconds': generatedAtEpochSeconds,
      'metaSchemaVersion': stamp['metaSchemaVersion'],
      'classCount': stamp['classCount'],
      'rootCount': stamp['rootCount'],
      'containerRoot': stamp['containerRoot'],
      'actualClassCount': classes,
      'actualRootCount': roots,
    },
    'check': {
      'nowEpochSeconds': nowEpochSeconds,
      'maxAgeDays': maxAgeDays,
      'ageSeconds': ageSeconds,
      'isAged': isAged,
      'classCountDisagrees': classCountDisagrees,
      'rootCountDisagrees': rootCountDisagrees,
      'countsDisagree': countsDisagree,
      'isStale': isAged || countsDisagree,
      'warnings': warnings,
    },
  };
}

/// The generation-stamp corpus. Every runtime parses the five stamp keys the
/// exporter writes (`generatedAt`, `metaSchemaVersion`, `classCount`,
/// `rootCount`, `containerRoot`) and reaches the same staleness verdict, with
/// the same warning wording, from the same input.
///
/// Two properties are load-bearing and each has its own case:
///
/// * **Absent is not zero.** A snapshot predating the stamp keys must decode to
///   null counts, not `0` — reading absent as zero would make every pre-stamp
///   export look like it had been truncated to nothing.
/// * **A zone-less timestamp is read as UTC.** The exporter always writes `Z`,
///   but a staleness verdict that changed with the reader's local timezone
///   would itself be a defect, so the grammar fixes the fallback rather than
///   leaving it to each platform's `parse`.
///
/// Ages are expressed in whole seconds and thresholds in whole days so the
/// table carries no language's duration type.
Map<String, dynamic> _stampCases() {
  const full = {
    'generatedAt': '2026-07-20T08:00:00.000000Z',
    'metaSchemaVersion': 1,
    'classCount': 2,
    'rootCount': 1,
    'containerRoot': 'DemoProject',
  };
  const agedWarning =
      'Snapshot is 60 days old (threshold 14 days) — the model may have moved '
      'on since it was exported.';
  const classWarning =
      'Stamp declares 99 classes but the snapshot carries 2 — it was edited '
      'after export.';
  const rootWarning =
      'Stamp declares 7 document roots but the snapshot carries 1 — it was '
      'edited after export.';
  return {
    'defaultMaxAgeDays': 14,
    'cases': [
      _stampCase(
        name: 'a full stamp decodes all five keys',
        stamp: full,
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        ageSeconds: _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'a pre-stamp snapshot decodes to nulls, not zeroes',
        stamp: const {},
        nowEpochSeconds: _stampGeneratedAt + 60 * _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'an unparseable generatedAt degrades to null, rest still decodes',
        stamp: {...full, 'generatedAt': 'not-a-date'},
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'a +HH:MM offset resolves to the same instant as Z',
        stamp: {...full, 'generatedAt': '2026-07-20T10:00:00+02:00'},
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        ageSeconds: _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'a -HH:MM offset resolves to the same instant as Z',
        stamp: {...full, 'generatedAt': '2026-07-20T03:00:00-05:00'},
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        ageSeconds: _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'an offset without a colon is accepted',
        stamp: {...full, 'generatedAt': '2026-07-20T10:00:00+0200'},
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        ageSeconds: _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'a zone-less timestamp is read as UTC, not local time',
        stamp: {...full, 'generatedAt': '2026-07-20T08:00:00'},
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        ageSeconds: _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'an out-of-range month is unreadable, not rolled over',
        stamp: {...full, 'generatedAt': '2026-13-20T08:00:00Z'},
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'a day that does not exist in its month is unreadable',
        stamp: {...full, 'generatedAt': '2026-02-31T08:00:00Z'},
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'a date with no time is outside the grammar',
        stamp: {...full, 'generatedAt': '2026-07-20'},
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'a snapshot older than the threshold is aged',
        stamp: full,
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + 60 * _oneDay,
        ageSeconds: 60 * _oneDay,
        isAged: true,
        warnings: const [agedWarning],
      ),
      _stampCase(
        name: 'the age threshold is caller-controlled (tolerant)',
        stamp: full,
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + 60 * _oneDay,
        maxAgeDays: 90,
        ageSeconds: 60 * _oneDay,
        isAged: false,
      ),
      _stampCase(
        name: 'the age threshold is caller-controlled (strict)',
        stamp: full,
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        maxAgeDays: 0,
        ageSeconds: _oneDay,
        isAged: true,
        warnings: const [
          'Snapshot is 1 days old (threshold 0 days) — the model may have '
              'moved on since it was exported.'
        ],
      ),
      _stampCase(
        name: 'a declared class count that disagrees is flagged',
        stamp: {...full, 'classCount': 99},
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        ageSeconds: _oneDay,
        isAged: false,
        classCountDisagrees: true,
        warnings: const [classWarning],
      ),
      _stampCase(
        name: 'a declared root count that disagrees is flagged',
        stamp: {...full, 'rootCount': 7},
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + _oneDay,
        ageSeconds: _oneDay,
        isAged: false,
        rootCountDisagrees: true,
        warnings: const [rootWarning],
      ),
      _stampCase(
        name: 'age and count findings are independent and both reported',
        stamp: {...full, 'classCount': 99, 'rootCount': 7},
        generatedAtEpochSeconds: _stampGeneratedAt,
        nowEpochSeconds: _stampGeneratedAt + 60 * _oneDay,
        ageSeconds: 60 * _oneDay,
        isAged: true,
        classCountDisagrees: true,
        rootCountDisagrees: true,
        warnings: const [agedWarning, classWarning, rootWarning],
      ),
      _stampCase(
        name: 'a snapshot without generatedAt is never aged',
        stamp: const {
          'metaSchemaVersion': 1,
          'classCount': 2,
          'rootCount': 1,
          'containerRoot': 'DemoProject',
        },
        nowEpochSeconds: _stampGeneratedAt + 60 * _oneDay,
        isAged: false,
      ),
    ],
  };
}

/// The §4.2/§21 editability corpus: what `somEditabilityFor` classifies a
/// `(generated, documentVersion)` pair as, and what `checkSomModelVersion` then
/// does about it.
///
/// The expectations below are **written from the rules, not read back from the
/// runtime** — the same discipline as [_stampCases]. A table generated by
/// calling the implementation would agree with the reference by construction and
/// could never catch the reference being wrong, which is precisely what happened
/// here: five of the nine ports classified an unparseable `generated` version by
/// *throwing out of the non-throwing classifier*, and no golden could say so
/// because no golden asked.
///
/// Four things each case pins:
///
/// * `generated` / `documentVersion` — the inputs. `documentVersion` is `null`
///   for the never-stamped case; the four ports whose signature takes a
///   non-nullable string (Go, Rust, C, C++) read `null` as `""`, the CS4-D2
///   empty-string sentinel, so those two cases coincide there and are separate
///   cases everywhere else.
/// * `editability` — the §21 classification, spelled as the Dart constant name
///   (the corpus convention; each port maps it to its own spelling).
/// * `rejects` — whether `checkSomModelVersion` refuses. Not "throws": C returns
///   non-zero, Go returns an `error`, Rust returns `Err`. The refusal is the
///   contract; the mechanism is the language's.
/// * `message` — the refusal text, `null` when editable. This is the half a user
///   actually reads, and it carries the one distinction the classification
///   cannot: `invalidVersion` has **two** messages, depending on which of the
///   two versions failed to parse.
///
/// The version pairs are chosen so that a plausible wrong implementation fails:
/// a lower major is `readOnlyCrossMajor` and not `editable` (cross-major is
/// symmetric, not an ordering), and minors compare numerically in both
/// directions, so a port that compares the stamps as strings fails `2.10` vs
/// `2.9` one way or the other.
Map<String, dynamic> _editabilityCases() {
  // The object model's own version for most cases. `2.3` leaves room on both
  // sides in both components, so every neighbour is expressible.
  const gen = '2.3';
  Map<String, dynamic> c({
    required String name,
    String generated = gen,
    required String? documentVersion,
    required String editability,
    String? message,
  }) =>
      {
        'name': name,
        'generated': generated,
        'documentVersion': documentVersion,
        'editability': editability,
        'rejects': message != null,
        'message': message,
      };
  String badStamp(String v) =>
      'document model version "$v" is not a valid major.minor';
  String crossMajor(int docMajor, int genMajor) =>
      'document major version $docMajor differs from the object model major '
      'version $genMajor; cross-major documents are read-only';
  String newerMinor(String doc, String generated) =>
      'document model version $doc is newer than the object model version '
      '$generated; an older object model cannot edit a newer document';
  return {
    'cases': [
      c(
        name: 'a document at the model\'s own version is editable',
        documentVersion: '2.3',
        editability: 'editable',
      ),
      c(
        name: 'an older minor of the same major is editable, and upgraded on '
            'edit',
        documentVersion: '2.1',
        editability: 'editable',
      ),
      c(
        name: 'a newer minor of the same major is rejected',
        documentVersion: '2.4',
        editability: 'rejectedNewerMinor',
        message: newerMinor('2.4', gen),
      ),
      c(
        name: 'a higher major is read-only, not rejected-newer',
        documentVersion: '3.0',
        editability: 'readOnlyCrossMajor',
        message: crossMajor(3, 2),
      ),
      // The case that separates "cross-major" from "older": 1.9 is *behind* 2.3
      // in every component, so an implementation that treats major as an
      // ordering rather than an identity calls this editable.
      c(
        name: 'a lower major is read-only too — cross-major is an identity, '
            'not an ordering',
        documentVersion: '1.9',
        editability: 'readOnlyCrossMajor',
        message: crossMajor(1, 2),
      ),
      c(
        name: 'an absent stamp is a brand-new document and is editable',
        documentVersion: null,
        editability: 'editable',
      ),
      c(
        name: 'an empty stamp is the same never-stamped sentinel',
        documentVersion: '',
        editability: 'editable',
      ),
      c(
        name: 'a single-component stamp is not a major.minor',
        documentVersion: '1',
        editability: 'invalidVersion',
        message: badStamp('1'),
      ),
      c(
        name: 'a non-numeric minor is not a major.minor',
        documentVersion: '1.x',
        editability: 'invalidVersion',
        message: badStamp('1.x'),
      ),
      c(
        name: 'a three-component stamp is not a major.minor either',
        documentVersion: '1.2.3',
        editability: 'invalidVersion',
        message: badStamp('1.2.3'),
      ),
      // The two lexicographic traps. As strings, '2.9' > '2.10'; as versions it
      // is the other way round, so a port that compares the raw stamps gets
      // exactly one of these two wrong whichever way it leans.
      c(
        name: 'minors compare numerically: 2.9 is older than 2.10',
        generated: '2.10',
        documentVersion: '2.9',
        editability: 'editable',
      ),
      c(
        name: 'and in the rejecting direction: 2.10 is newer than 2.9',
        generated: '2.9',
        documentVersion: '2.10',
        editability: 'rejectedNewerMinor',
        message: newerMinor('2.10', '2.9'),
      ),
      // §21 calls somEditabilityFor a *pure*, *non-throwing* classifier. An
      // unparseable `generated` is therefore classified, not raised — a
      // classifier a caller must still guard with try/catch has given that
      // caller nothing over the throwing check it was meant to replace. The
      // refusal message still names the *generated* version, because that is
      // the one that failed to parse: `invalidVersion` is one outcome with two
      // causes, and the message is where they separate.
      c(
        name: 'an unparseable generated version is classified, not raised',
        generated: 'x.y',
        documentVersion: '2.3',
        editability: 'invalidVersion',
        message: '"x.y" is not a valid major.minor version',
      ),
      // And the ordering that makes the previous case survivable: the absent
      // stamp is answered before `generated` is ever looked at, so a facade
      // built with a broken version constant can still open a new document.
      c(
        name: 'an absent stamp is answered before generated is parsed at all',
        generated: 'x.y',
        documentVersion: null,
        editability: 'editable',
      ),
    ],
  };
}

/// The Markdown **import-rejection** corpus (SOM §11.7). Each case is a
/// Markdown source plus two expectations that have to hold *together*:
///
///  * `rejections` — every block the importer could not place, in the order it
///    reports them, pinned on the full `(line, reason, anchor, message)`. The
///    message is pinned for the same reason the §21 version table pins it: a
///    reason is one classification with several causes, and the message is
///    where they separate. `unknownSection` alone has three causes (no match at
///    this position, an unresolvable parent, no such document root) and
///    `orphanContent` two (before the root, before a form's first field label);
///    a table that pinned only the reason would let a port collapse them.
///  * `document` — what *did* land, as the `toJson()` document map. This is the
///    half that catches the failure §11.7 exists to prevent. A port that drops
///    an unplaceable block silently fails `rejections`; a port that reports the
///    block and then abandons the rest of the parse fails `document`. Neither
///    assertion alone says "reported, **not** dropped, and the rest still
///    landed" — only the pair does.
///
/// The document map is the same shape as `state.json`, so every port asserts it
/// with the canonicalising comparison it already uses for the memory-landing
/// test: stage → `loadJson` → `toJson`.
///
/// The sources are written against the committed model's `DEMO` root, using
/// heading texts that match the schema defaults wherever a stored headline is
/// not the point of the case — an incidental headline in the expected document
/// would be noise a reader has to explain away.
Map<String, dynamic> _markdownImportCases() {
  // Each message is written once and reused, so a case cannot silently disagree
  // with its neighbour about what the same rejection reads like.
  const beforeRoot = 'text before the document root heading';
  const noComment = 'heading carries no <!--[SECTION-ID]--> headline comment';
  const orphanParent = 'section nested under an unresolvable parent';
  const noRoot = 'no document root with this section id (known: DEMO, SIDE)';
  const childUnderLeaf = 'child heading under a value-leaf or form section';
  const noValue = 'no value text under this section heading';
  String noResolve(String parent) =>
      'section id does not resolve against the schema tree at this position '
      '(under "$parent")';

  Map<String, dynamic> rej(
          int line, String reason, String? anchor, String message) =>
      {'line': line, 'reason': reason, 'anchor': anchor, 'message': message};

  // The source is written as a line list so a case's expected line numbers can
  // be read off its own literal — the whole table is about line numbers, and a
  // triple-quoted blob would hide them.
  Map<String, dynamic> c({
    required String name,
    required List<String> markdown,
    required List<Map<String, dynamic>> rejections,
    required Map<String, dynamic> document,
  }) =>
      {
        'name': name,
        'markdown': '${markdown.join('\n')}\n',
        'rejections': rejections,
        'document': document,
      };

  return {
    'cases': [
      c(
        name: 'text before the document root is reported, and the rest of the '
            'document still imports',
        markdown: [
          'Stray preamble.', //                                        1
          '', //                                                       2
          '# <!--[DEMO]--> Demo Document', //                          3
          '', //                                                       4
          '## <!--[TTL]--> Document Title', //                         5
          '', //                                                       6
          'Hello', //                                                  7
        ],
        rejections: [rej(1, 'orphanContent', null, beforeRoot)],
        document: {
          'content': {'DEMO/TTL': 'Hello'}
        },
      ),
      // A block is reported *once*, at its heading — not once per body line.
      // The body lines are the tempting second report, and a port that emits
      // one per line passes a rejections-are-non-empty check but fails here.
      c(
        name: 'a heading with no headline comment is reported once, at the '
            'heading, not once per swallowed body line',
        markdown: [
          '# <!--[DEMO]--> Demo Document', //                          1
          '', //                                                       2
          '## <!--[TTL]--> Document Title', //                         3
          '', //                                                       4
          'Hello', //                                                  5
          '', //                                                       6
          '## A Heading With No Comment', //                           7
          '', //                                                       8
          'body under the ignored heading', //                         9
          'and a second body line', //                                10
          '', //                                                      11
          '## <!--[PRI]--> Priority', //                              12
          '', //                                                      13
          'high', //                                                  14
        ],
        rejections: [
          rej(7, 'malformedHeading', 'A Heading With No Comment', noComment),
        ],
        document: {
          'content': {'DEMO/PRI': 'high', 'DEMO/TTL': 'Hello'}
        },
      ),
      c(
        name: 'an id that does not resolve at its position is reported against '
            'the parent path, and its siblings still import',
        markdown: [
          '# <!--[DEMO]--> Demo Document', //                          1
          '', //                                                       2
          '## <!--[TTL]--> Document Title', //                         3
          '', //                                                       4
          'Hello', //                                                  5
          '', //                                                       6
          '## <!--[NOSUCH]--> Not In The Schema', //                   7
          '', //                                                       8
          'dropped', //                                                9
          '', //                                                      10
          '## <!--[PRI]--> Priority', //                              11
          '', //                                                      12
          'high', //                                                  13
        ],
        rejections: [
          rej(7, 'unknownSection', 'NOSUCH', noResolve('DEMO')),
        ],
        document: {
          'content': {'DEMO/PRI': 'high', 'DEMO/TTL': 'Hello'}
        },
      ),
      // The nesting case: an unresolvable parent must not swallow its children
      // silently. Both the parent and the child are reported, with different
      // messages — the child's names *why* it could not be placed.
      c(
        name: 'a section under an unresolvable parent is reported too, not '
            'swallowed with it',
        markdown: [
          '# <!--[DEMO]--> Demo Document', //                          1
          '', //                                                       2
          '## <!--[NOSUCH]--> Not In The Schema', //                   3
          '', //                                                       4
          '### <!--[TTL]--> Document Title', //                        5
          '', //                                                       6
          'Hello', //                                                  7
          '', //                                                       8
          '## <!--[PRI]--> Priority', //                               9
          '', //                                                      10
          'high', //                                                  11
        ],
        rejections: [
          rej(3, 'unknownSection', 'NOSUCH', noResolve('DEMO')),
          rej(5, 'unknownSection', 'TTL', orphanParent),
        ],
        document: {
          'content': {'DEMO/PRI': 'high'}
        },
      ),
      // A wrong *root* is the one unknownSection that cannot name a parent
      // path, so it names the roots that do exist instead. Nothing lands.
      c(
        name: 'a root id that is not a document root names the roots that are, '
            'and nothing lands',
        markdown: [
          '<!-- docspec: demo-document/1.0 -->', //                     1
          '# <!--[WRONGROOT]--> Wrong Root', //                         2
          '', //                                                        3
          '## <!--[TTL]--> Document Title', //                          4
          '', //                                                        5
          'Hello', //                                                   6
        ],
        rejections: [
          rej(2, 'unknownSection', 'WRONGROOT', noRoot),
          rej(4, 'unknownSection', 'TTL', orphanParent),
        ],
        document: const <String, dynamic>{},
      ),
      c(
        name: 'a child heading under a value leaf is a kind mismatch, and the '
            'leaf keeps its own value',
        markdown: [
          '# <!--[DEMO]--> Demo Document', //                          1
          '', //                                                       2
          '## <!--[TTL]--> Document Title', //                         3
          '', //                                                       4
          'Hello', //                                                  5
          '', //                                                       6
          '### <!--[STS]--> Status', //                                7
          '', //                                                       8
          'open', //                                                   9
          '', //                                                      10
          '## <!--[PRI]--> Priority', //                              11
          '', //                                                      12
          'high', //                                                  13
        ],
        rejections: [rej(7, 'kindMismatch', 'STS', childUnderLeaf)],
        document: {
          'content': {'DEMO/PRI': 'high', 'DEMO/TTL': 'Hello'}
        },
      ),
      // `missingValue` is the one reason raised when a frame *closes*, not when
      // a heading opens — so it is reported at the heading's line even though
      // the parser only knows at the next heading. Its anchor is the resolved
      // path, not the raw id: the section did resolve, it just carried nothing.
      c(
        name: 'a value-leaf heading with no body is a missing value, anchored '
            'on the resolved path and reported at its own heading line',
        markdown: [
          '# <!--[DEMO]--> Demo Document', //                          1
          '', //                                                       2
          '## <!--[TTL]--> Document Title', //                         3
          '', //                                                       4
          'Hello', //                                                  5
          '', //                                                       6
          '## <!--[PRI]--> Priority', //                               7
          '', //                                                       8
          '## <!--[CNT]--> Count', //                                  9
          '', //                                                      10
          '3', //                                                     11
        ],
        rejections: [rej(7, 'missingValue', 'DEMO/PRI', noValue)],
        document: {
          'content': {'DEMO/CNT': '3', 'DEMO/TTL': 'Hello'}
        },
      ),
      // The `orphanContent` case that is *not* one. `DET` is a `@Form`, and
      // prose before its first `Field:` label is the form's preamble (SOM §11.4
      // rule 7) — it has a home, so it lands in the form's own content slot and
      // nothing is rejected. Kept as a case precisely because it used to be a
      // rejection: a port that still reports here has not read rule 7.
      c(
        name: 'text in a form section before the first field label is the '
            "form's preamble, and lands beside the fields",
        markdown: [
          '# <!--[DEMO]--> Demo Document', //                          1
          '', //                                                       2
          '## <!--[DET]--> Details & Contacts', //                     3
          '', //                                                       4
          'loose prose with no field label', //                        5
          'Owner: Bob', //                                             6
          'Contact: bob@example.com', //                               7
        ],
        rejections: const <Map<String, dynamic>>[],
        document: {
          'content': {'DEMO/DET': 'loose prose with no field label'},
          'forms': {
            'DEMO/DET': {'contact': 'bob@example.com', 'owner': 'Bob'}
          },
          'headlines': {'DEMO/DET': 'Details & Contacts'},
        },
      ),
      // Inside a `-LST` container any heading id is a legal item (it becomes
      // the item's stored id), so the list case has to nest one level deeper —
      // under an *item* — to reach the resolver at all. The list membership
      // still lands, and the sibling after the rejected block still resolves.
      c(
        name: 'an id that does not resolve under a list item is reported '
            'against the item path, and the list still imports',
        markdown: [
          '# <!--[DEMO]--> Demo Document', //                          1
          '', //                                                       2
          '## <!--[TTL]--> Document Title', //                         3
          '', //                                                       4
          'Hello', //                                                  5
          '', //                                                       6
          '## <!--[items]--> Items', //                                7
          '', //                                                       8
          '### <!--[items-1]--> Task 1', //                            9
          '', //                                                      10
          'First', //                                                 11
          '', //                                                      12
          '#### <!--[BOGUS]--> Bogus', //                             13
          '', //                                                      14
          'dropped', //                                               15
          '', //                                                      16
          '#### <!--[STS]--> Status', //                              17
          '', //                                                      18
          'open', //                                                  19
        ],
        rejections: [
          rej(13, 'unknownSection', 'BOGUS', noResolve('DEMO/items-1')),
        ],
        document: {
          'content': {
            'DEMO/TTL': 'Hello',
            'DEMO/items-1/STS': 'open',
            'DEMO/items-1/label': 'First',
          },
          'lists': {
            'DEMO/items': {
              'seq': 1,
              'items': ['DEMO/items-1'],
            }
          },
        },
      ),
      // The mixed case the protocol is really about: all five reasons in one
      // document, coexisting with content, a form and their headline. It also
      // pins the *report order*, which is not simply ascending by line —
      // `missingValue` for `PRI` (line 17) is raised when `PRI`'s frame closes,
      // i.e. while the parser is already looking at line 19.
      c(
        name: 'all five reasons in one document: every rejected block is '
            'reported and everything else still lands',
        markdown: [
          'Stray preamble before the root.', //                        1
          '', //                                                       2
          '# <!--[DEMO]--> Demo Document', //                          3
          '', //                                                       4
          '## <!--[TTL]--> Document Title', //                         5
          '', //                                                       6
          'Hello', //                                                  7
          '', //                                                       8
          '### <!--[STS]--> Status', //                                9
          '', //                                                      10
          'open', //                                                  11
          '', //                                                      12
          '## An Unmarked Heading', //                                13
          '', //                                                      14
          'swallowed body', //                                        15
          '', //                                                      16
          '## <!--[PRI]--> Priority', //                              17
          '', //                                                      18
          '## <!--[NOSUCH]--> Not In The Schema', //                  19
          '', //                                                      20
          'dropped', //                                               21
          '', //                                                      22
          '## <!--[DET]--> Details & Contacts', //                    23
          '', //                                                      24
          'loose prose with no field label', //                       25
          'Owner: Bob', //                                            26
          '', //                                                      27
          '## <!--[CNT]--> Count', //                                 28
          '', //                                                      29
          '3', //                                                     30
        ],
        rejections: [
          rej(1, 'orphanContent', null, beforeRoot),
          rej(9, 'kindMismatch', 'STS', childUnderLeaf),
          rej(13, 'malformedHeading', 'An Unmarked Heading', noComment),
          rej(17, 'missingValue', 'DEMO/PRI', noValue),
          rej(19, 'unknownSection', 'NOSUCH', noResolve('DEMO')),
        ],
        document: {
          'content': {
            'DEMO/CNT': '3',
            'DEMO/DET': 'loose prose with no field label',
            'DEMO/TTL': 'Hello',
          },
          'forms': {
            'DEMO/DET': {'owner': 'Bob'}
          },
          'headlines': {'DEMO/DET': 'Details & Contacts'},
        },
      ),
    ],
  };
}

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
  // Declared out of declaration order, and interleaved with two names the
  // model does not declare: one case exercises both halves of the rule —
  // declared fields by position, undeclared ones after and alphabetically
  // (SOM §9, "Form-field order"). Without the undeclared pair, a port that
  // simply dropped what it could not place would pass.
  const formFields = ['zzz', 'author', 'aaa', 'title'];
  return {
    'model': meta,
    'contentPaths': contentPaths,
    'expectedOrder': order.orderPaths(contentPaths),
    'formPath': 'DEMO/HEAD',
    'formFields': formFields,
    'expectedFormOrder': order.orderFormFields('DEMO/HEAD', formFields),
  };
}

// --- The SOM §14 DocSpecs tier ----------------------------------------------

/// The corpus schema for the DocSpecs tier — hand-authored in the
/// schema-generator output shape (SOM §13), deliberately small and shaped so a
/// single schema can provoke every one of the eleven §14 rules.
///
/// It is a *fixture input*, not a golden: the ports load this exact YAML and
/// must reach the same verdicts on the same markdown. The `pattern-check-id`
/// here uses `[0-9]+`, stricter than the `.+` stem check the generator emits,
/// because the cases exercise the regex *mechanism* — the validator is
/// regex-agnostic and any authored pattern is legal in a schema.
///
/// What each feature is here for: `text-required` (textRequired),
/// `max-text-length` (textLengthOut), `pattern-check-id` (idPatternMismatch),
/// `subsection-types` cardinality — `goals`/`goal-item` min 1 for
/// missingRequiredSection, `steps`/`step` min 2 for tooFewItems, `gsum` max 1
/// for tooManyItems — a form-type with a required field and a field
/// pattern-check (missingRequiredField, fieldPatternMismatch), and a non-form
/// `format` (formatMismatch, alongside the `title-format` root-id check).
const _docSpecsSchemaYaml = '''
title-format: "# <!--[D00]--> Demo Document"
section-types:
  goal-item:
    prefix: GOAL_ITEM_
    pattern-check-id:
      pattern: "^GOAL-ITEM-[0-9]+\$"
      error-message: IDs of this section must match GOAL-ITEM-xxx
  d00-ovr:
    prefix: D00_OVR
    text-required: true
  d00-hdr:
    prefix: D00_HDR
    format: header-form
  gsum:
    prefix: GSUM
    max-text-length: 20
  diag:
    prefix: DIAG
    format: mermaid
  step:
    prefix: STEP_
  steps:
    prefix: STEPS
    subsection-types:
      step:
        min-count: 2
        max-count: infinite
  goals:
    prefix: GOALS
    subsection-types:
      goal-item:
        min-count: 1
        max-count: infinite
      gsum:
        max-count: 1
form-types:
  header-form:
    fields:
      - fieldname: author
        required: true
      - fieldname: reviewer
        pattern-check:
          pattern: "^[A-Z]"
          error-message: Reviewer must start with an uppercase letter
document:
  sections:
    d00-ovr:
      section-type: d00-ovr
    d00-hdr:
      section-type: d00-hdr
      optional: true
    goals:
      section-type: goals
      optional: true
    steps:
      section-type: steps
      optional: true
    diag:
      section-type: diag
      optional: true
''';

/// The clean document every violation case is a minimal edit of. Keeping one
/// base means each case's expected line numbers stay legible: the edit and the
/// reported line are visibly the same place.
const _docSpecsValidDoc = '''
<!-- docspec: demo-document/1.0 -->
# <!--[D00]--> Demo Document

Intro text.

## <!--[D00-OVR]--> Overview

Some overview text.

## <!--[D00-HDR]--> Header

Author: Alice
Reviewer: Bob

## <!--[GOALS]--> Goals

### <!--[GOAL-ITEM-1]--> Goal 1

First goal.

### <!--[GOAL-ITEM-2]--> Goal 2

Second goal.
''';

/// The hand-authored markdown inputs, one per named case. Every one of the
/// eleven §14 rules is provoked by at least one of these; the final case
/// provokes three at once, pinning the "never fail-fast" contract as a
/// cross-language obligation rather than a Dart-only unit test.
List<Map<String, String>> _docSpecsMarkdownCases() {
  Map<String, String> c(String name, String markdown) =>
      {'name': name, 'markdown': markdown};
  return [
    c('valid', _docSpecsValidDoc),
    c(
        'unknownSection-unresolvableId',
        _docSpecsValidDoc.replaceFirst(
            '### <!--[GOAL-ITEM-2]--> Goal 2', '### <!--[XYZ-2]--> Goal 2')),
    c(
        'unknownSection-disallowedPosition',
        _docSpecsValidDoc.replaceFirst(
            '### <!--[GOAL-ITEM-2]--> Goal 2', '### <!--[DIAG]--> Diagram')),
    c(
        'missingRequiredSection-documentSlot',
        _docSpecsValidDoc.replaceFirst(
            '## <!--[D00-OVR]--> Overview\n\nSome overview text.\n\n', '')),
    c(
        'missingRequiredSection-subsection',
        _docSpecsValidDoc.replaceFirst(
            '\n### <!--[GOAL-ITEM-1]--> Goal 1\n\nFirst goal.\n'
            '\n### <!--[GOAL-ITEM-2]--> Goal 2\n\nSecond goal.\n',
            '\nGoals prose but no goal items.\n')),
    c('idPatternMismatch',
        _docSpecsValidDoc.replaceFirst('GOAL-ITEM-2', 'GOAL-ITEM-B')),
    c('tooFewItems',
        '$_docSpecsValidDoc\n## <!--[STEPS]--> Steps\n\n'
            '### <!--[STEP-1]--> Step one\n\nOnly one step.\n'),
    c(
        'tooManyItems',
        '$_docSpecsValidDoc\n### <!--[GSUM]--> Summary\n\nOne.\n'
            '\n### <!--[GSUM]--> Summary\n\nTwo.\n'),
    c('missingRequiredField',
        _docSpecsValidDoc.replaceFirst('Author: Alice\n', '')),
    c('fieldPatternMismatch',
        _docSpecsValidDoc.replaceFirst('Reviewer: Bob', 'Reviewer: bob')),
    c('textRequired',
        _docSpecsValidDoc.replaceFirst('Some overview text.\n\n', '')),
    c(
        'textLengthOut',
        '$_docSpecsValidDoc\n### <!--[GSUM]--> Summary\n\n'
            'A goals summary far longer than the twenty characters allowed.\n'),
    c('formatMismatch-rootId',
        _docSpecsValidDoc.replaceFirst('# <!--[D00]-->', '# <!--[D99]-->')),
    c('formatMismatch-missingFence',
        '$_docSpecsValidDoc\n## <!--[DIAG]--> Diagram\n\nno fence here\n'),
    c('malformedHeading',
        '$_docSpecsValidDoc\n## Plain Heading With No Comment\n\nBody.\n'),
    c(
        'multipleViolations-neverFailFast',
        _docSpecsValidDoc
            .replaceFirst('Author: Alice\n', '')
            .replaceFirst('Reviewer: Bob', 'Reviewer: bob')
            .replaceFirst('GOAL-ITEM-2', 'GOAL-ITEM-B')),
  ];
}

/// The DocSpecs corpus table: the hand-authored markdown plus the violation
/// list the *reference* implementation produces for it. SOM §14 names the Dart
/// rule/sectionId/line triples as the golden reference, so the expectations are
/// computed rather than transcribed — a hand-typed line number would only be a
/// second, drift-prone source of truth. The message text is deliberately not
/// carried: it is prose, and pinning it across nine languages would make
/// rewording a nine-package change for no contractual gain.
List<Map<String, Object?>> _docSpecsCases() {
  final validator =
      DocSpecsValidator(DocSpecsSchema.fromYamlText(_docSpecsSchemaYaml));
  return [
    for (final c in _docSpecsMarkdownCases())
      {
        'name': c['name'],
        'markdown': c['markdown'],
        'violations': [
          for (final v in validator.validateMarkdown(c['markdown']!))
            {'rule': v.rule.name, 'sectionId': v.sectionId, 'line': v.line},
        ],
      },
  ];
}

// ---------------------------------------------------------------------------
// spec_text_pattern / spec_query / spec_node_creation corpus builders
// ---------------------------------------------------------------------------

/// The portable pattern subset's own table.
///
/// Separate from [_queryCases] on purpose. The query table only exercises the
/// handful of patterns the fixture's text happens to make interesting, while
/// the matcher is nine hand-written transcriptions of a backtracking algorithm
/// — the place a port is *most* likely to differ. Greedy give-back, the
/// empty-match advance rule, class parsing corners and every compile rejection
/// are pinned here so a divergence names the pattern that broke rather than
/// showing up as a missing query hit three layers up.
///
/// Each case is either a match case (`spans`) or a rejection (`error: true`).
List<Map<String, dynamic>> _patternCases() {
  final cases = <Map<String, dynamic>>[];

  void match(String pattern, String text,
      {bool regex = true, bool caseInsensitive = false}) {
    final p = regex
        ? SomTextPattern.compile(pattern, caseInsensitive: caseInsensitive)
        : SomTextPattern.literal(pattern, caseInsensitive: caseInsensitive);
    cases.add({
      'pattern': pattern,
      'regex': regex,
      'caseInsensitive': caseInsensitive,
      'text': text,
      'spans': [
        for (final s in p.allMatches(text)) [s.start, s.end],
      ],
    });
  }

  void rejects(String pattern) {
    // Computed, never asserted by hand: if compile stops rejecting, the
    // generator throws here under UPDATE_CORPUS instead of quietly writing a
    // case that says nothing.
    try {
      SomTextPattern.compile(pattern);
      throw StateError('pattern "$pattern" was expected to be rejected');
    } on SomPatternError {
      cases.add({'pattern': pattern, 'regex': true, 'error': true});
    }
  }

  // -- literals are wholly uninterpreted --
  match('a.c', 'a.c abc', regex: false);
  match('aa', 'aaaa', regex: false);
  match('aba', 'ababa', regex: false); // overlaps are not both reported
  match('', 'ab', regex: false); // empty match advances one character
  match('[x]', 'a[x]b', regex: false);

  // -- the grammar --
  match('a.c', 'abc adc a c');
  match('a.*c', 'abcxxc'); // greedy, then gives back until the tail fits
  match('a.*', 'abc');
  match('ab+', 'a ab abb');
  match('ab?c', 'ac abc');
  match('a*', 'aaa b'); // zero-width matches around a non-member
  match('[a-c1]x', 'ax bx cx dx 1x');
  match('[^abc]', 'abcd');
  match('[]a]', ']a'); // POSIX: `]` right after `[` is a member
  match('[a-]', 'a-'); // trailing `-` is a literal
  match('^a', 'aa');
  match(r'a$', 'aa');
  match(r'^ab$', 'ab');
  match(r'^a$', 'a\na'); // anchors bind to the text, not to a line
  match(r'a\.c', 'a.c abc');
  match(r'\(a\)', '(a)');
  match('a|b', 'a|b'); // outside the grammar, so an ordinary literal
  match('(a)', '(a)');
  match('.*', ''); // the empty text still offers one start position

  // -- ASCII-only case folding --
  match('abc', 'ABC', caseInsensitive: true);
  match('ABC', 'abc', caseInsensitive: true);
  match('[a-z]+', 'ABC', caseInsensitive: true);
  match('[A-Z]+', 'abc', caseInsensitive: true);
  match('ä', 'Ä', caseInsensitive: true); // non-ASCII is deliberately not folded
  match('Hello', 'hello', regex: false, caseInsensitive: true);

  // -- offsets are UTF-16 code units, not bytes and not code points --
  // The folding case above yields no spans, so on its own it says nothing
  // about how a port indexes text. These do: each puts a match *after*
  // non-ASCII text, so the reported start differs under every plausible
  // indexing. In "äöü-x" the `x` starts at code unit 4, but at byte 7 in
  // UTF-8; in "𝄞-x" (a non-BMP clef, one code point, a surrogate pair) it
  // starts at code unit 4 but at code point 3 — which is what separates a
  // UTF-16 port from one indexing by code point, the two that agree
  // everywhere in the BMP.
  match('x', 'äöü-x'); // `x` at unit 4 — it would be byte 7 in UTF-8
  match('x', '𝄞-x'); // `x` at unit 3 — it would be code point 2
  // And `.` is one code *unit*, not one character: against a lone surrogate
  // pair it matches twice, each half. Unlovely, but it is the contract the
  // offsets already imply, and pinning it stops a port whose `.` walks
  // characters (the natural reading in Python, Go and Rust) from quietly
  // reporting one span where the reference reports two.
  match('.', '𝄞');

  // -- compile rejections --
  rejects('*a');
  rejects('^*');
  rejects(r'$?');
  rejects('a+*');
  rejects('[abc');
  rejects('[z-a]');
  rejects('ab\\');
  rejects('[a\\');
  rejects(r'\w');
  rejects(r'\d');
  rejects(r'\s');
  rejects(r'\1');
  rejects(r'slip\w+');

  return cases;
}

/// The `spec_query` surface over the corpus fixture (SOM §9).
///
/// One case per query, holding the query in its wire form plus the full match
/// list in document order. Because the list is ordered and complete, replaying
/// it also pins the cursor: `toList()` must produce exactly this, and `count`
/// must equal its length. `take` is pinned by [_cursorCases], which needs a
/// script rather than a table.
///
/// Three dimensions the fixture cannot reach — `mapsTo`, `detailedIn` and a
/// `headline` sourced from a class/field doc comment — are covered by
/// negative cases only (a filter that must match nothing), because no class or
/// field in `model.meta.json` carries those annotations. Making them positive
/// needs a fixture change, which is tracked separately.
List<Map<String, dynamic>> _queryCases(SpecModel model, SpecDocument doc) {
  final engine = SpecQueryEngine(model: model, document: doc);
  final cases = <Map<String, dynamic>>[];

  void run(String name, SpecQuery q, Map<String, dynamic> wire) {
    final matches = engine.query(q).toList();
    cases.add({
      'name': name,
      'query': wire,
      'matches': [
        for (final m in matches)
          {
            'path': m.path,
            'kind': m.kind.name,
            'classId': m.classId,
            'headline': m.headline,
            'snippet': m.snippet,
            'spans': [
              for (final s in m.matchSpans) [s.start, s.end],
            ],
          },
      ],
    });
  }

  // -- text dimension --
  run('text substring in a content leaf', const SpecQuery(text: 'Hello'),
      {'text': 'Hello'});
  run('text substring spanning several nodes', const SpecQuery(text: 'Line'),
      {'text': 'Line'});
  run('text substring in a form field', const SpecQuery(text: 'bob@'),
      {'text': 'bob@'});
  run('text substring in a stored headline',
      const SpecQuery(text: 'Executive'), {'text': 'Executive'});
  run('text matching nothing', const SpecQuery(text: 'no-such-text'),
      {'text': 'no-such-text'});
  run('text is case-sensitive by default', const SpecQuery(text: 'HELLO'),
      {'text': 'HELLO'});
  run('text case-insensitive',
      const SpecQuery(text: 'HELLO', caseInsensitive: true),
      {'text': 'HELLO', 'caseInsensitive': true});
  run('text with several spans in one value', const SpecQuery(text: 'card'),
      {'text': 'card'});
  run('regex over content', const SpecQuery(text: 'Line [a-z]+', regex: true),
      {'text': 'Line [a-z]+', 'regex': true});
  run('regex anchored to the whole value',
      const SpecQuery(text: r'^Hello$', regex: true),
      {'text': r'^Hello$', 'regex': true});
  run('regex case-insensitive',
      const SpecQuery(text: '[A-Z]lice', regex: true, caseInsensitive: true),
      {'text': '[A-Z]lice', 'regex': true, 'caseInsensitive': true});

  // -- structural dimensions --
  run('kinds filter', const SpecQuery(kinds: {SpecNodeKind.form}),
      {'kinds': ['form']});
  run('kinds filter admitting several kinds',
      const SpecQuery(kinds: {SpecNodeKind.list, SpecNodeKind.root}),
      {'kinds': ['list', 'root']});
  run('className filter', const SpecQuery(className: 'Item'),
      {'className': 'Item'});
  run('sectionIdExact filter', const SpecQuery(sectionIdExact: 'TTL'),
      {'sectionIdExact': 'TTL'});
  run('sectionIdPrefix filter', const SpecQuery(sectionIdPrefix: 'CARD'),
      {'sectionIdPrefix': 'CARD'});
  run('pathGlob within one segment', const SpecQuery(pathGlob: 'DEMO/*'),
      {'pathGlob': 'DEMO/*'});
  run('pathGlob crossing segments', const SpecQuery(pathGlob: 'DEMO/**'),
      {'pathGlob': 'DEMO/**'});
  run('pathGlob with a literal tail', const SpecQuery(pathGlob: '**/label'),
      {'pathGlob': '**/label'});
  run('pathGlob matching nothing', const SpecQuery(pathGlob: 'NOPE/*'),
      {'pathGlob': 'NOPE/*'});

  // -- state dimension (SpecStateFilter — both constants) --
  run('state nonEmpty', const SpecQuery(state: SpecStateFilter.nonEmpty),
      {'state': 'nonEmpty'});
  run('state empty', const SpecQuery(state: SpecStateFilter.empty),
      {'state': 'empty'});
  run('state empty within one subtree',
      const SpecQuery(state: SpecStateFilter.empty, pathGlob: 'DEMO/REG/**'),
      {'state': 'empty', 'pathGlob': 'DEMO/REG/**'});

  // -- annotation dimensions (Card carries both; see its meta entry) --
  // Positive first: a negative case alone is satisfied just as well by a
  // runtime that never implemented the filter, so it pins nothing on its own.
  run('mapsTo filter selects the annotated class\'s nodes',
      const SpecQuery(mapsTo: 'CS00-CARD'), {'mapsTo': 'CS00-CARD'});
  run('detailedIn filter selects the annotated class\'s nodes',
      const SpecQuery(detailedIn: 'BP00-CARDS'), {'detailedIn': 'BP00-CARDS'});
  run('mapsTo filter matches nothing when the target is unknown',
      const SpecQuery(mapsTo: 'SomeTarget'), {'mapsTo': 'SomeTarget'});
  run('detailedIn filter matches nothing when the target is unknown',
      const SpecQuery(detailedIn: 'SomeDoc'), {'detailedIn': 'SomeDoc'});

  // -- combinations: the filters are conjunctive --
  run('text and kind together',
      const SpecQuery(text: 'card', kinds: {SpecNodeKind.form}),
      {'text': 'card', 'kinds': ['form']});
  run('prefix and state together',
      const SpecQuery(
          sectionIdPrefix: 'CARD', state: SpecStateFilter.nonEmpty),
      {'sectionIdPrefix': 'CARD', 'state': 'nonEmpty'});
  run('every dimension unset returns the whole document in order',
      const SpecQuery(), const <String, dynamic>{});

  return cases;
}

/// The node projection surface (`SpecQueryEngine.projectNodes`), which the
/// search index is built from. Ordered, so it pins the structural walk itself —
/// the same walk the query's candidate set comes from.
List<Map<String, dynamic>> _projectionCases(SpecModel model, SpecDocument doc) {
  final engine = SpecQueryEngine(model: model, document: doc);
  return [
    for (final p in engine.projectNodes())
      {
        'path': p.path,
        'kind': p.kind.name,
        'classId': p.classId,
        'sectionId': p.sectionId,
        'mapsTo': p.mapsTo,
        'detailedIn': p.detailedIn,
        'headline': p.headline,
        'searchableStrings': p.searchableStrings,
        'hasValue': p.hasValue,
      },
  ];
}

/// The fixture's CodeSpecs area catalogue — the machine-readable form of
/// `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6, cut down to the six areas the
/// fixture's routing verdicts name.
///
/// The `CE-*` codes, canonical ids, `@CodeSpecKind` values, `Cs*` annotations
/// and "Built on" cells are the **real** §4.1 rows, and the seven slices are the
/// real §4.4.3 table with its real citation edges: the catalogue is an *input*
/// to the extractor, so a synthetic one would pin the plumbing while leaving the
/// vocabulary — the half a port can get wrong in nine identical ways — unpinned.
/// What is cut down is only *how many* rows, never what a row says.
Map<String, dynamic> _codeSpecsCatalogJson() => {
      'source': 'codespecs_mapping.md §4.1 + §4.4.3 + §4.4.6',
      'slices': [
        {
          'number': 1,
          'title': 'Shared const catalogues',
          'project': '<app>_codespec_shared',
          'cites': <int>[],
        },
        {
          'number': 2,
          'title': 'Shared contract',
          'project': '<app>_codespec_shared',
          'cites': [1],
        },
        {
          'number': 3,
          'title': 'Server persistence & configuration',
          'project': '<app>_codespec_server',
          'cites': [1, 2],
        },
        {
          'number': 4,
          'title': 'Server behaviour',
          'project': '<app>_codespec_server',
          'cites': [1, 2, 3],
        },
        {
          'number': 5,
          'title': 'Client interaction core',
          'project': '<app>_codespec_client',
          'cites': [1, 2],
        },
        {
          'number': 6,
          'title': 'Client presentation & shell',
          'project': '<app>_codespec_client',
          'cites': [1, 5],
        },
        {
          'number': 7,
          'title': 'Server operational',
          'project': '<app>_codespec_server',
          'cites': [3, 4],
        },
      ],
      // In §4.1 catalogue order, which §4.4.6 rule 2 uses as its tie-break and
      // which the extractor emits its extracts in.
      'areas': [
        {
          'code': 'CE-FM',
          'canonicalId': 'Form',
          'part': 'form',
          'annotations': ['@CsForm'],
          'builtOn': '`TomForm`, `TomFormChildContainer` (`tom_flutter_ui`)',
          'attributeSurface': 'codespecs_mapping.md §5.7.2',
          'slices': [5],
          'authoringSteps': [23],
        },
        {
          'code': 'CE-TX',
          'canonicalId': 'Text',
          'part': 'text',
          'annotations': ['@CsText'],
          'builtOn': '`TomText` (`tom_flutter_ui`) + `TomTextResourceProvider` '
              '(`tom_core_kernel`); message/i18n-key model `TomMessageKey` / '
              '`TomMessageKeyRegistry` (`tom_core_codespecs`)',
          'attributeSurface': 'codespecs_mapping.md §5.8, §5.21',
          // The fixture's one LOCUS-SPLIT area: SCC-A keys in slice 1, the copy
          // in slice 5. It is what makes `projects` a list rather than a field.
          'slices': [1, 5],
          'authoringSteps': [2, 24],
        },
        {
          'code': 'CE-DB',
          'canonicalId': 'DataAccess',
          'part': 'dataAccess',
          'annotations': ['@CsTable', '@CsColumn', '@CsRepository'],
          'builtOn': 'Tom persistence model + repository (`tom_core_server`)',
          'attributeSurface': 'codespecs_mapping.md §5.13',
          'slices': [3],
          'authoringSteps': [10],
        },
        {
          'code': 'CE-ST',
          'canonicalId': 'ViewState',
          'part': 'viewState',
          'annotations': ['@CsViewModel'],
          'builtOn': '`TomObservable` / `TomObject` (`tom_core_kernel`)',
          'attributeSurface': 'codespecs_mapping.md §5.4',
          'slices': [5],
          'authoringSteps': [23],
        },
        {
          'code': 'CE-NV',
          'canonicalId': 'Navigation',
          'part': 'navigation',
          'annotations': ['@CsRoute', '@CsScreenFlow'],
          'builtOn': '`TomPageRoute` (`tom_flutter_ui`); route-id + screen-flow '
              'model (`tom_core_codespecs`)',
          'attributeSurface': 'codespecs_mapping.md §5.11',
          'slices': [5],
          'authoringSteps': [23],
        },
        {
          // Deliberately entry-free: nothing in the fixture routes to it. An
          // area with no content still gets an extract, because "the
          // specification says nothing about this" is a finding the authoring
          // agent must be shown rather than a file that fails to appear.
          'code': 'CE-ER',
          'canonicalId': 'ErrorResult',
          'part': 'errorResult',
          'annotations': ['@CsError'],
          'builtOn': '**gap** — plain annotated result/error classes in '
              '`<app>_codespec_shared`; no framework counterpart',
          'attributeSurface': 'codespecs_mapping.md §7',
          'slices': [1],
          'authoringSteps': [2],
        },
      ],
    };

/// The Phase-4 extract generator (`codespecs_mapping.md` §1.1.1) — the machine
/// half that turns a filled document into one bounded, cited extract per
/// CodeSpecs area.
///
/// Four things are pinned, because four things are what the surface exists to
/// get right: a section routed to several areas appears in all of them
/// undeduplicated, a `@FollowUpKind` subtree appears in none, a section routed
/// nowhere is a hard error rather than a silent skip, and every scalar emitted
/// occurs character-for-character in its source. The last is the one that keeps
/// the generator on its side of the `codespecs_derivation_contract.md` §2.8
/// **C1** line, so it is carried as its own table rather than left to a reader.
Map<String, dynamic> _codeSpecsExtractCases(
    SpecModel model, SpecDocument doc) {
  final catalogJson = _codeSpecsCatalogJson();
  final catalog = CodeSpecsAreaCatalog.fromJson(catalogJson);
  final extractor =
      CodeSpecsExtractor(model: model, document: doc, catalog: catalog);

  Map<String, dynamic> entryJson(CodeSpecsExtractEntry e) => {
        'sectionId': e.sectionId,
        'headline': e.headline,
        'instanceId': e.instanceId,
        'path': e.path,
        'className': e.className,
        'fieldName': e.fieldName,
        'formField': e.formField,
        'routedBy': e.routedBy,
        'routedAt': e.routedAt,
        'routingNote': e.routingNote,
        'value': e.value,
      };

  return {
    'catalog': catalogJson,
    // The `routings` diagnostic: which verdict each walked class carried and
    // where the marker sat. Pinned separately from the extracts because a port
    // can route right and emit wrong, or the reverse, and a single table cannot
    // tell those two apart.
    'routings': [
      for (final r in extractor.routings())
        {
          'path': r.path,
          'className': r.className,
          'verdict': r.verdict.name,
          'values': r.values,
          'note': r.note,
          'declaredAt': r.declaredAt,
        },
    ],
    'extracts': [
      for (final x in extractor.extractAll())
        {
          'area': x.area.code,
          'canonicalId': x.area.canonicalId,
          'part': x.area.kindValue,
          'documentRoot': x.documentRoot,
          'fileStem': x.fileStem,
          // Derived from the slice graph rather than authored on the area, so
          // a port that transcribes the catalogue but not the derivation fails
          // here — CE-TX is the case that discriminates, spanning two slices
          // in two different projects.
          'projects': x.projects,
          'citableParts': x.citableParts,
          'entries': [for (final e in x.entries) entryJson(e)],
          // The two emitted artifacts, byte for byte: the YAML is the artifact
          // of record and the Markdown is the view rendered from it.
          'yaml': x.toYaml(),
          'markdown': x.toMarkdown(),
        },
    ],
    // The `ROUTE-TOTAL` hard error. It carries its OWN model rather than
    // mutating the shared one — the shared `model.meta.json` is a valid model
    // by construction (every class carries a verdict), and a port in a language
    // without cheap structural editing should not have to break it to run this
    // case. The document is empty: the walk descends into a complex member
    // whether or not it holds a value, which is exactly why an unrouted section
    // cannot hide behind being unpopulated.
    'errorCases': [
      {
        'name': 'a section carrying none of the three verdicts is a hard error',
        'model': {
          'metaSchemaVersion': 1,
          'modelVersion': 1,
          'roots': [
            {'type': 'Root', 'title': 'Root', 'sectionId': 'ROOT'}
          ],
          'classes': {
            'Root': {
              'name': 'Root',
              'sectionId': 'ROOT',
              'annotations': [
                {
                  'name': 'Document',
                  'arguments': {'title': 'Root'}
                },
              ],
              'fields': [
                {
                  'name': 'orphan',
                  'kind': 'complex',
                  'sectionId': 'ORP',
                  'type': 'Orphan'
                },
              ],
            },
            'Orphan': {
              'name': 'Orphan',
              'sectionId': 'ORP',
              'fields': [
                {'name': 'body', 'kind': 'content', 'sectionId': 'ORP-BDY'},
              ],
            },
          },
        },
        'state': <String, dynamic>{},
        'expect': {
          'path': 'ROOT/ORP',
          'className': 'Orphan',
          // The message is prose and deliberately unpinned; the invariant id it
          // must name is the contract.
          'messageContains': 'ROUTE-TOTAL',
          // The non-throwing diagnostic reports the same node instead of
          // throwing, so both halves of the surface are covered by one case.
          'routingVerdict': 'unrouted',
        },
      },
    ],
    // Root scoping (`codespecs_prompt.md` §5). A Phase-4 run extracts from ONE
    // specification document, so the walk has exactly one root; the two ways to
    // get that wrong are both loud rather than silent. The model carries two
    // `@Document` roots because a single-root model cannot tell "walks the
    // named root" apart from "walks every root" — the union and the correct
    // answer coincide.
    //
    // `rootType` absent means the caller named nothing. `expect.paths` is every
    // entry path across every extract, in order, which is what makes the union
    // visible: walking both roots would list the other root's path too.
    //
    // `expect.routingVerdicts` is the verdict of every class node the SAME walk
    // reaches, which pins the claim the constructor-resolved root exists to
    // make: `routings()` and `extractAll()` cannot disagree about what was
    // walked. It is also the corpus's only producer of `documentRoot` — `Beta`
    // is a bare `@Document` root, and no other table walks one.
    // `expect.fails` cases pin `messageContains` on a normative fragment — the
    // three failure modes are distinguished by `holds no value` (a named root
    // the document never populates, the `D13CodeSpecsProjection` mistake),
    // `populated roots` (ambiguous) and `no document root` (unknown name).
    //
    // That an empty document over a SINGLE-root model still resolves is pinned
    // by `errorCases` above rather than here: it only reaches `ROUTE-TOTAL`
    // because root resolution succeeded over an empty `state`.
    'rootCases': [
      {
        'name': 'an explicit root scopes the walk to that root alone',
        'model': _codeSpecsTwoRootModelJson(),
        'state': {
          'content': {'ALP/TTL': 'Alpha title', 'BET/NTS/NTE': 'Beta note'},
        },
        'rootType': 'Alpha',
        'expect': {
          'fails': false,
          'root': 'Alpha',
          'documentRoot': 'ALP',
          'paths': ['ALP/TTL'],
          'routingVerdicts': ['feedsCode'],
        },
      },
      {
        'name': 'the root defaults to the one the document populates',
        'model': _codeSpecsTwoRootModelJson(),
        'state': {
          'content': {'BET/NTS/NTE': 'Beta note'},
        },
        'expect': {
          'fails': false,
          'root': 'Beta',
          'documentRoot': 'BET',
          'paths': ['BET/NTS/NTE'],
          'routingVerdicts': ['documentRoot', 'feedsCode'],
        },
      },
      {
        'name': 'a section id names its root as well as the type does',
        'model': _codeSpecsTwoRootModelJson(),
        'state': {
          'content': {'ALP/TTL': 'Alpha title'},
        },
        'rootType': 'ALP',
        'expect': {
          'fails': false,
          'root': 'Alpha',
          'documentRoot': 'ALP',
          'paths': ['ALP/TTL'],
          'routingVerdicts': ['feedsCode'],
        },
      },
      {
        'name': 'naming a root the document never populates is an error',
        'model': _codeSpecsTwoRootModelJson(),
        'state': {
          'content': {'ALP/TTL': 'Alpha title'},
        },
        'rootType': 'Beta',
        'expect': {
          'fails': true,
          'path': 'BET',
          'className': 'Beta',
          'messageContains': 'holds no value',
        },
      },
      {
        'name': 'a document populating more than one root is an error',
        'model': _codeSpecsTwoRootModelJson(),
        'state': {
          'content': {'ALP/TTL': 'Alpha title', 'BET/NTS/NTE': 'Beta note'},
        },
        'expect': {
          'fails': true,
          'path': '',
          'className': '',
          'messageContains': 'populated roots',
        },
      },
      {
        'name': 'a root the model does not have is an error',
        'model': _codeSpecsTwoRootModelJson(),
        'state': {
          'content': {'ALP/TTL': 'Alpha title'},
        },
        'rootType': 'Gamma',
        'expect': {
          'fails': true,
          'path': '',
          'className': 'Gamma',
          'messageContains': 'no document root',
        },
      },
    ],
  };
}

/// Two `@Document` roots over two disjoint path spaces, each routed to one
/// area, for the `rootCases` table.
///
/// The two roots are deliberately shaped differently, because the walk root is
/// the one node whose verdict depends on being the root. `Alpha` carries
/// `@CodeSpecKind` itself; `Beta` is a bare `@Document` whose content is routed
/// by a child section — the shape of a real specification document, and the
/// only place the corpus produces the `documentRoot` verdict now that the walk
/// enters exactly one root (`codespecs_prompt.md` §5).
Map<String, dynamic> _codeSpecsTwoRootModelJson() => {
      'metaSchemaVersion': 1,
      'modelVersion': 1,
      'roots': [
        {'type': 'Alpha', 'title': 'Alpha', 'sectionId': 'ALP'},
        {'type': 'Beta', 'title': 'Beta', 'sectionId': 'BET'},
      ],
      'classes': {
        'Alpha': {
          'name': 'Alpha',
          'sectionId': 'ALP',
          'annotations': [
            {
              'name': 'Document',
              'arguments': {'title': 'Alpha'}
            },
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.form']
              }
            },
          ],
          'fields': [
            {'name': 'title', 'kind': 'content', 'sectionId': 'TTL'},
          ],
        },
        'Beta': {
          'name': 'Beta',
          'sectionId': 'BET',
          // No routing verdict: a bare `@Document` root is structurally exempt
          // from `ROUTE-TOTAL` (a root is the document, not a section of it),
          // so walking it yields `documentRoot` and its child carries the
          // routing.
          'annotations': [
            {
              'name': 'Document',
              'arguments': {'title': 'Beta'}
            },
          ],
          'fields': [
            {
              'name': 'notes',
              'kind': 'section',
              'type': 'BetaNotes',
              'sectionId': 'NTS'
            },
          ],
        },
        'BetaNotes': {
          'name': 'BetaNotes',
          'sectionId': 'NTS',
          'annotations': [
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.text']
              }
            },
          ],
          'fields': [
            {'name': 'note', 'kind': 'content', 'sectionId': 'NTE'},
          ],
        },
      },
    };

/// Cursor semantics that a result *table* cannot express: partial consumption
/// via `take`, `count` reporting only what remains, and the edit-stability rule
/// — a candidate whose list item was removed after the cursor was built is
/// skipped rather than resolved against a stale path.
///
/// A script rather than a table because each step depends on the cursor
/// position the previous step left behind.
List<Map<String, dynamic>> _cursorScript(SpecModel model) {
  final doc = _buildDocument();
  final engine = SpecQueryEngine(model: model, document: doc);
  final steps = <Map<String, dynamic>>[];

  // A query with several hits, consumed in pieces.
  const q = {'sectionIdPrefix': 'REF'};
  final cursor = engine.query(const SpecQuery(sectionIdPrefix: 'REF'));
  steps.add({'op': 'open', 'query': q});
  steps.add({
    'op': 'count',
    'expect': cursor.count,
  });
  steps.add({
    'op': 'take',
    'n': 1,
    'expect': cursor.take(1).map((m) => m.path).toList(),
  });
  steps.add({
    'op': 'count',
    'expect': cursor.count, // one fewer: count is "remaining", not "total"
  });
  steps.add({
    'op': 'next',
    'expect': cursor.next()?.path,
  });
  steps.add({'op': 'next', 'expect': cursor.next()?.path});
  steps.add({'op': 'toList', 'expect': cursor.toList().map((m) => m.path).toList()});

  // Edit stability: build a cursor over the item list, then delete an item
  // before draining it. The stale candidate must be skipped silently.
  final live = engine.query(const SpecQuery(pathGlob: 'DEMO/items-*'));
  steps.add({'op': 'open', 'query': {'pathGlob': 'DEMO/items-*'}});
  steps.add({'op': 'removeListItem', 'itemPath': 'DEMO/items-1'});
  doc.removeListItem('DEMO/items-1');
  steps.add({
    'op': 'toList',
    'expect': live.toList().map((m) => m.path).toList(),
  });

  return steps;
}

/// The `spec_node_creation` gate (`checkAddNode`) and the creator built on it.
///
/// Every [SpecCreationCode] constant is exercised by a rejection case, and the
/// accepting cases pin what a successful add produces — the child path and, for
/// a pattern-bearing list, the generated section id.
List<Map<String, dynamic>> _nodeCreationCases(SpecModel model) {
  final cases = <Map<String, dynamic>>[];

  /// A `checkAddNode` probe against a freshly built document, so cases are
  /// order-independent and can be replayed in any sequence.
  void check(String name, String parentPath, String childSegment,
      {String? itemId, SpecDocument? against}) {
    final doc = against ?? _buildDocument();
    final err = checkAddNode(model, doc, parentPath, childSegment,
        itemId: itemId);
    cases.add({
      'name': name,
      'parentPath': parentPath,
      'childSegment': childSegment,
      if (itemId != null) 'itemId': itemId,
      'accepted': err == null,
      // The `code`, not the message: the code is the contract, the message is
      // prose. Pinning prose across nine languages makes rewording a
      // nine-package change and guarantees nothing the code does not already.
      if (err != null) 'code': err.code.name,
    });
  }

  // -- accepted --
  check('add an item to an unpatterned list', 'DEMO', 'items');
  check('add an item to a patterned list with an explicit id', 'DEMO',
      'REF-LST', itemId: 'REF-9');
  check('add a card to the card list', 'DEMO', 'CARD-LST',
      itemId: 'CARD-NEW');
  check('add a nested list item', 'DEMO/META', 'tags');

  // -- notAContainer --
  check('a content leaf accepts no child', 'DEMO/TTL', 'anything');
  check('a form section accepts no child', 'DEMO/DET', 'owner');

  // -- unknownChild --
  check('a segment naming no field of the parent class', 'DEMO', 'nope');
  check('a field of a different class is still unknown here', 'DEMO/META',
      'items');

  // -- patternMismatch --
  check('an id not matching the list pattern', 'DEMO', 'REF-LST',
      itemId: 'XXX-1');
  check('an id matching a different list pattern', 'DEMO', 'CARD-LST',
      itemId: 'REF-1');

  // -- duplicateSectionId --
  check('an id already taken by a sibling item', 'DEMO', 'REF-LST',
      itemId: 'REF-SPEC');
  check('an id already taken in the card list', 'DEMO', 'CARD-LST',
      itemId: 'CARD-ALPHA');

  // -- cardinalityExceeded --
  check('a second instance of a single-valued complex field', 'DEMO', 'META');
  check('a second instance of a single-valued form field', 'DEMO', 'DET');

  return cases;
}

/// The creator's own script: `SpecNodeCreator.add` applied in sequence, so each
/// step sees the document the previous one produced. Pins the generated paths
/// and ids, which the stateless [_nodeCreationCases] probes cannot.
List<Map<String, dynamic>> _nodeCreationScript(SpecModel model) {
  final doc = _buildDocument();
  final creator = SpecNodeCreator(model, doc);
  final steps = <Map<String, dynamic>>[];

  void add(String parentPath, String childSegment,
      {String? itemId, int month = 3, int day = 4}) {
    final path = creator.add(parentPath, childSegment,
        itemId: itemId, date: DateTime(2026, month, day));
    steps.add({
      'op': 'add',
      'parentPath': parentPath,
      'childSegment': childSegment,
      if (itemId != null) 'itemId': itemId,
      'month': month,
      'day': day,
      'expectPath': path,
      'expectId': doc.itemSectionId(path),
    });
  }

  void rejects(String parentPath, String childSegment, {String? itemId}) {
    // Computed, not asserted: if `add` stops throwing, the generator fails
    // under UPDATE_CORPUS rather than writing a vacuous case.
    try {
      creator.add(parentPath, childSegment,
          itemId: itemId, date: DateTime(2026, 3, 4));
      throw StateError('add($parentPath, $childSegment) should have thrown');
    } on SpecCreationError catch (e) {
      steps.add({
        'op': 'addThrows',
        'parentPath': parentPath,
        'childSegment': childSegment,
        if (itemId != null) 'itemId': itemId,
        // `add` throws the gate's own typed error, so the script pins the code
        // as well as the refusal — a port that rejects for the wrong reason
        // fails here rather than passing on the strength of any throw at all.
        'expectCode': e.code.name,
      });
    }
  }

  add('DEMO', 'items');
  add('DEMO', 'REF-LST');
  add('DEMO', 'CARD-LST', itemId: 'CARD-BETA');
  add('DEMO/META', 'tags');
  rejects('DEMO/TTL', 'anything');
  rejects('DEMO', 'nope');
  rejects('DEMO', 'REF-LST', itemId: 'XXX-1');
  rejects('DEMO', 'CARD-LST', itemId: 'CARD-ALPHA');
  steps.add({'op': 'finalState', 'expect': doc.toJson()});

  return steps;
}
