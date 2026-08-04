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

  test('every validation code the reference runtime emits has a corpus case',
      () {
    // The recurrence guard (csrf3). `validation_cases.json` is what makes the
    // other eight runtimes prove they implement a check: a case expecting a
    // code a runtime does not emit fails that runtime's own conformance
    // runner. A code with NO case is therefore invisible — which is exactly
    // how `danglingReference` (csrb3) and `oneOfCaseMismatch` (csmb6) stayed
    // Dart-only for two rounds while the harness reported nine-way parity.
    //
    // Asserting from `SpecValidationCode.values` rather than from a second
    // hand-kept list is the point: adding an enum constant is the very act
    // that makes this test demand its corpus case, so the eight ports cannot
    // be left behind silently again.
    final covered = <String>{
      for (final c in (jsonDecode(read('validation_cases.json')) as List)
          .cast<Map<String, dynamic>>())
        for (final e in (c['errors'] as List).cast<Map<String, dynamic>>())
          e['code'] as String,
    };
    final uncovered = SpecValidationCode.values
        .map((c) => c.name)
        .where((name) => !covered.contains(name))
        .toList();
    expect(uncovered, isEmpty,
        reason: 'validation_cases.json exercises no case producing '
            '${uncovered.join(', ')} — add one (and implement the check in '
            'all nine runtimes) rather than shipping a Dart-only code');
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
        case 'setHeadline':
          ed.setHeadline(s['path'] as String, s['value'] as String?);
        case 'headline':
          expect(ed.headline(s['path'] as String), s['expect'],
              reason: 'headline ${s['path']}');
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
        case 'removeListItem':
          expect(ed.removeListItem(s['itemPath'] as String), s['expect'],
              reason: 'removeListItem ${s['itemPath']}');
        case 'clearSection':
          ed.clearSection(s['path'] as String);
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
}

// --- Fixture construction (the reference data the corpus is generated from) --

/// A SYNTHETIC codec-exerciser — NOT a model-convention reference.
///
/// This compact, hand-authored meta-model exists to exercise the codec's full
/// field-kind matrix across all nine language runtimes, so it deliberately
/// contains shapes that do NOT occur in the real `tom_specs_model` and must not
/// be read as conventions to imitate:
///   * `count` (kind `scalar`, type `int`) — the real model has ZERO non-String
///     primitive leaves;
///   * id-less `content` leaves (e.g. `Item.label`, `Control.owner`) — real
///     content leaves carry a field- or class-level `@SectionId`;
///   * `Control` — a class with TWO `content` leaves; real classes have exactly
///     one `content` body.
/// They exist only to force the codec down every branch (int scalar, id
/// fallback, transparent member, multi-content). For a convention-conformant
/// fixture, see the `realistic (convention-conformant) model` group in
/// `spec_document_yaml_test.dart`.
///
/// The kind coverage: content (incl. a multi-line block-scalar value), enum,
/// scalar, a two-field `@Form`, a `@Min`-constrained complex list, a nested
/// complex section, and a (declared-but-unpopulated) scalar list for resolution
/// coverage.
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
      'classCount': 11,
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
                // YRD7: typed form fields — stored as plain text
                // (`FieldName: value`), converted at the type boundary by the
                // shared somParse*/somFormat* helpers, natively typed in the
                // generic editor and the generated facades.
                {'name': 'estimate', 'label': 'Estimate', 'type': 'int'},
                {'name': 'weight', 'label': 'Weight', 'type': 'double'},
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
          'fields': [
            {'name': 'note', 'kind': 'content'},
          ],
        },
        'Sidecar': {
          'name': 'Sidecar',
          'sectionId': 'SIDE',
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
          ],
          'fields': [
            // `summary` keeps a field-level content key (`CTRL-SUM summary:`);
            // `owner` is id-less and keeps a bare content key (`owner:`).
            {'name': 'summary', 'kind': 'content', 'sectionId': 'CTRL-SUM'},
            {'name': 'owner', 'kind': 'content'},
          ],
        },
        'Item': {
          'name': 'Item',
          // YRD4: class-level @Headline default — drives the item title stem
          // ('Task 1', 'Task 2') instead of itemTitleStem('Item').
          'headline': 'Task',
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
  // YRD7: typed form-field values in their canonical plain-text store form —
  // exactly the strings somFormatInt(8) / somFormatDouble(2.5) /
  // somFormatBool(true) / somFormatEnumName('high', …) produce, so the yaml/md
  // goldens pin the typed fields' serialization as ordinary `FieldName: value`.
  d.setFormField('DEMO/DET', 'estimate', '8');
  d.setFormField('DEMO/DET', 'weight', '2.5');
  d.setFormField('DEMO/DET', 'active', 'true');
  d.setFormField('DEMO/DET', 'priority', 'high');
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
/// dangling/non-leaf paths must raise the language's argument error.
List<Map<String, dynamic>> _editorScript() => [
      // --- typed value leaves ------------------------------------------------
      {'op': 'setValue', 'path': 'DEMO/CNT', 'value': 3},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': 3},
      {'op': 'rawContent', 'path': 'DEMO/CNT', 'expect': '3'},
      {'op': 'setValue', 'path': 'DEMO/CNT', 'value': null},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': null},
      {'op': 'rawContent', 'path': 'DEMO/CNT', 'expect': null},
      // Forgiving read: raw garbage in the store reads as null, not an error.
      {'op': 'setContent', 'path': 'DEMO/CNT', 'value': 'abc'},
      {'op': 'value', 'path': 'DEMO/CNT', 'expect': null},
      {'op': 'setContent', 'path': 'DEMO/CNT', 'value': ''},
      // Enum leaf: validated constant-name strings.
      {'op': 'setValue', 'path': 'DEMO/PRI', 'value': 'high'},
      {'op': 'value', 'path': 'DEMO/PRI', 'expect': 'high'},
      {'op': 'rawContent', 'path': 'DEMO/PRI', 'expect': 'high'},
      {'op': 'setValueThrows', 'path': 'DEMO/PRI', 'value': 'urgent'},
      {'op': 'value', 'path': 'DEMO/PRI', 'expect': 'high'},
      // Plain content leaf.
      {'op': 'setValue', 'path': 'DEMO/TTL', 'value': 'Hello'},
      {'op': 'value', 'path': 'DEMO/TTL', 'expect': 'Hello'},
      // Strict resolution: dangling and non-leaf paths are rejected.
      {'op': 'setValueThrows', 'path': 'DEMO/ghost', 'value': 'x'},
      {'op': 'setValueThrows', 'path': 'DEMO/items', 'value': 'x'},
      // --- typed form fields (int / double / bool / enum) --------------------
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'owner',
        'value': 'Bob'},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'owner',
        'expect': 'Bob'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'value': 8},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': 8},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'estimate',
        'expect': '8'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'weight',
        'value': 2.5},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'weight',
        'expect': 2.5},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'weight',
        'expect': '2.5'},
      {'op': 'setFormValue', 'path': 'DEMO/DET', 'field': 'active',
        'value': true},
      {'op': 'formValue', 'path': 'DEMO/DET', 'field': 'active',
        'expect': true},
      {'op': 'rawFormField', 'path': 'DEMO/DET', 'field': 'active',
        'expect': 'true'},
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
      {'op': 'setValue', 'path': 'DEMO/REF-LST-1', 'value': 'spec §1.2'},
      {'op': 'value', 'path': 'DEMO/REF-LST-1', 'expect': 'spec §1.2'},
      {'op': 'addListItem', 'listPath': 'DEMO/CARD-LST', 'month': 3, 'day': 4,
        'expectPath': 'DEMO/CARD-LST-1', 'expectId': 'CARD-CD1'},
      {'op': 'setFormValue', 'path': 'DEMO/CARD-LST-1/content',
        'field': 'note', 'value': 'first card'},
      // clearSection drops every value under a subtree; removeListItem drops
      // one item.
      {'op': 'setValue', 'path': 'DEMO/META/OWNR', 'value': 'alice'},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/META', 'expect': true},
      {'op': 'clearSection', 'path': 'DEMO/META'},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/META', 'expect': false},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/CARD-LST-1', 'expect': true},
      {'op': 'removeListItem', 'itemPath': 'DEMO/CARD-LST-1', 'expect': true},
      {'op': 'hasValuesUnder', 'prefix': 'DEMO/CARD-LST-1', 'expect': false},
      {'op': 'removeListItem', 'itemPath': 'DEMO/CARD-LST-9', 'expect': false},
      // Headlines through the editor (resolution-checked).
      {'op': 'setHeadline', 'path': 'DEMO/SUM', 'value': 'Exec Summary'},
      {'op': 'headline', 'path': 'DEMO/SUM', 'expect': 'Exec Summary'},
      {'op': 'setHeadline', 'path': 'DEMO/SUM', 'value': ''},
      {'op': 'headline', 'path': 'DEMO/SUM', 'expect': null},
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
