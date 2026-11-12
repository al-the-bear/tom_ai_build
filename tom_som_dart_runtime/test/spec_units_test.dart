// SOM §11.2 `units`: the generation units a section goes to. Kept exactly as
// `codeSpec` is — a sparse store by section path, the Markdown heading key
// `units="a,b"` after `codeSpec`, the YAML key `units` after `codeSpec`, the
// facade's `$units`, the snapshot's `units` map — and checked by the instance
// tier's phase 8.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The shared corpus model (a copy kept in the package, see
/// `docspecs_validator_test.dart`): the demo root with the generation-unit
/// register `DEMO/DLV-LST` (`Deliverable`, `DeliverableRoute`).
SpecModel _corpusModel() => SpecModel.fromJson(
  jsonDecode(File('test/fixtures/corpus/model.meta.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// A register declaring `u_a` and `u_b`, both building something.
SpecDocument _register() {
  final d = SpecDocument();
  final a = d.addListItem('DEMO/DLV-LST');
  d.setFormField('$a/content', 'unitId', 'u_a');
  d.setFormField('$a/content', 'component', 'ARCM-COMP-A');
  final b = d.addListItem('DEMO/DLV-LST');
  d.setFormField('$b/content', 'unitId', 'u_b');
  d.setFormField('$b/content', 'deploymentTarget', 'DEPTAR-DEPL-B');
  return d;
}

class _Node extends SomNode {
  _Node(super.doc, super.path);
}

void main() {
  group('the store', () {
    test('units / setUnits / unitsPaths; empty clears', () {
      final d = SpecDocument();
      expect(d.units('DEMO/TTL'), isNull);
      d.setUnits('DEMO/TTL', 'u_a,u_b');
      expect(d.units('DEMO/TTL'), 'u_a,u_b');
      expect(d.unitsPaths, ['DEMO/TTL']);
      expect(d.isEmpty, isFalse);
      expect(d.hasValuesUnder('DEMO'), isTrue);
      d.setUnits('DEMO/TTL', '');
      expect(d.units('DEMO/TTL'), isNull);
      expect(d.unitsPaths, isEmpty);
      expect(d.isEmpty, isTrue);
    });

    test('the snapshot carries `units` beside `codeSpecs`, sorted', () {
      final d = SpecDocument()
        ..setCodeSpec('DEMO/TTL', 'A')
        ..setUnits('DEMO/TTL', 'u_b')
        ..setUnits('DEMO/SUM', 'u_a');
      final json = d.toJson();
      expect(json.keys, ['codeSpecs', 'units']);
      expect((json['units'] as Map).keys, ['DEMO/SUM', 'DEMO/TTL']);
      final back = SpecDocument()..loadJson(jsonDecode(jsonEncode(json)));
      expect(back.toJson(), json);
      // No units, no key.
      expect(SpecDocument().toJson().containsKey('units'), isFalse);
    });

    test('captureState / restoreState and the fingerprint see units', () {
      final d = SpecDocument()..setUnits('DEMO/TTL', 'u_a');
      final state = d.captureState();
      d.setUnits('DEMO/TTL', 'u_b');
      expect(d.captureState().fingerprint, isNot(state.fingerprint));
      d.restoreState(state);
      expect(d.units('DEMO/TTL'), 'u_a');
    });

    test('removeValuesUnder clears units under the prefix', () {
      final d = SpecDocument()
        ..setUnits('DEMO/notes', 'u_a')
        ..setUnits('DEMO/notes/NOTE-BDY', 'u_b')
        ..setUnits('DEMO/TTL', 'u_a');
      d.removeValuesUnder('DEMO/notes');
      expect(d.unitsPaths, ['DEMO/TTL']);
    });

    test('units move with their list item', () {
      final model = _corpusModel();
      final d = SpecDocument();
      final first = d.addListItem('DEMO/items');
      final second = d.addListItem('DEMO/items');
      d.setContent('$first/label', 'one');
      d.setContent('$second/label', 'two');
      d.setUnits(second, 'u_a');
      d.moveListItem(model, second, 0);
      expect(d.units('DEMO/items-1'), 'u_a');
      expect(d.units('DEMO/items-2'), isNull);
    });

    test('a path normalizer re-keys units', () {
      final d = SpecDocument()..setUnits('demo/TTL', 'u_a');
      d.installPathNormalizer((p) => p.replaceFirst('demo', 'DEMO'));
      expect(d.units('DEMO/TTL'), 'u_a');
      expect(d.unitsPaths, ['DEMO/TTL']);
    });
  });

  test(r'the facade reads and writes $units; null clears', () {
    final d = SpecDocument();
    final node = _Node(d, 'DEMO/TTL');
    expect(node.$units, isNull);
    node.$units = 'u_a';
    expect(d.units('DEMO/TTL'), 'u_a');
    expect(node.$units, 'u_a');
    node.$units = null;
    expect(node.$units, isNull);
    node.$units = 'u_b';
    node.$units = '';
    expect(d.unitsPaths, isEmpty);
  });

  group('Markdown', () {
    final model = _corpusModel();

    test('emits units after codeSpec in the heading comment', () {
      final d = SpecDocument()
        ..setContent('DEMO/TTL', 'Hello')
        ..setCodeSpec('DEMO/TTL', 'DemoTitle')
        ..setUnits('DEMO/TTL', 'u_a,u_b')
        ..setContent('DEMO/SUM', 'Sum')
        ..setUnits('DEMO/SUM', 'u_a');
      final md = d.toMarkdown(model);
      expect(
        md,
        contains(
          '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> '
          'Document Title\n',
        ),
      );
      expect(md, contains('## <!--[SUM] units="u_a"--> Summary\n'));
    });

    test('parses units in every quoting, beside or without codeSpec', () {
      const md =
          '# <!--[DEMO] units=u_root--> Demo Document\n\n'
          '## <!--[TTL] codeSpec="DemoTitle" units="u_a,u_b"--> Title\n\n'
          'Hello\n\n'
          "## <!--[SUM] units='u_c'--> Summary\n\n"
          'Sum\n\n'
          '## <!--[CNT] codeSpec="units=no"--> Count\n\n'
          '3\n';
      final result = SpecDocumentMarkdown(model, SpecDocument()).parse(md);
      expect(result.rejections, isEmpty);
      expect(result.units, {
        'DEMO': 'u_root',
        'DEMO/TTL': 'u_a,u_b',
        'DEMO/SUM': 'u_c',
      });
      expect(result.codeSpecs['DEMO/TTL'], 'DemoTitle');
      // A `units=` inside a quoted codeSpec value is not the key.
      expect(result.codeSpecs['DEMO/CNT'], 'units=no');
    });

    test('round-trips byte-stably through fromMarkdown', () {
      final d = _register()
        ..setContent('DEMO/TTL', 'Hello')
        ..setCodeSpec('DEMO/TTL', 'DemoTitle')
        ..setUnits('DEMO/TTL', 'u_a')
        ..setContent('DEMO/notes/NOTE-BDY', 'Body')
        ..setUnits('DEMO/notes', 'u_a,u_b');
      final md = d.toMarkdown(model);
      final back = SpecDocument.fromMarkdown(md, model).document;
      expect(back.units('DEMO/TTL'), 'u_a');
      expect(back.units('DEMO/notes'), 'u_a,u_b');
      expect(back.toMarkdown(model), md);
    });
  });

  group('YAML', () {
    final model = _corpusModel();
    final tree = buildSomMetaTree(model);
    String enc(SpecDocument d) =>
        SpecDocumentYaml.encode(document: d, tree: tree, modelVersion: '1.0');

    test('writes units right after codeSpec, promoting a scalar', () {
      final d = SpecDocument()
        ..setContent('DEMO/TTL', 'Hello')
        ..setHeadline('DEMO/TTL', 'Title')
        ..setCodeSpec('DEMO/TTL', 'DemoTitle')
        ..setUnits('DEMO/TTL', 'u_a')
        ..setContent('DEMO/CNT', '3')
        ..setUnits('DEMO/CNT', 'u_b')
        ..setContent('DEMO/notes/NOTE-BDY', 'Body')
        ..setUnits('DEMO/notes', 'u_a,u_b');
      final yaml = enc(d);
      expect(
        yaml,
        contains(
          '    TTL title:\n'
          '      headline: |2-\n        Title\n'
          '      codeSpec: |2-\n        DemoTitle\n'
          '      units: |2-\n        u_a\n'
          '      content: |2-\n        Hello\n',
        ),
      );
      // A non-text scalar keeps its plain content inside the mapping.
      expect(
        yaml,
        contains(
          '    CNT count:\n      units: |2-\n        u_b\n      content: 3\n',
        ),
      );
      expect(
        yaml,
        contains('    NOTE notes:\n      units: |2-\n        u_a,u_b\n'),
      );
      final back = SpecDocument.fromYaml(yaml, tree);
      expect(back.toJson(), d.toJson());
      expect(enc(back), yaml);
    });

    test('units on a form, a list container and a list item round-trip', () {
      final d = _register()
        ..setFormField('DEMO/DET', 'owner', 'Bob')
        ..setUnits('DEMO/DET', 'u_a')
        ..setUnits('DEMO/DLV-LST', 'u_b')
        ..setUnits('DEMO/DLV-LST-1', 'u_a');
      final tagItem = d.addListItem('DEMO/META/tags');
      d
        ..setContent(tagItem, 'on')
        ..setUnits(tagItem, 'u_b');
      final yaml = enc(d);
      final back = SpecDocument.fromYaml(yaml, tree);
      expect(back.toJson(), d.toJson());
      expect(enc(back), yaml);
    });

    test('refuses units where a child or form field is named `units`', () {
      final clash = SpecModel(
        roots: [SpecRoot(type: 'R', title: 'R', sectionId: 'R')],
        classes: {
          'R': SpecClass(
            name: 'R',
            sectionId: 'R',
            fields: [
              SpecField(name: 'units', kind: SpecFieldKind.content),
              SpecField(
                name: 'shape',
                kind: SpecFieldKind.form,
                sectionId: 'SHP',
                formFields: [
                  FormFieldSpec(name: 'units', label: 'Units', type: 'String'),
                ],
              ),
            ],
          ),
        },
      );
      final clashTree = buildSomMetaTree(clash);
      String encode(SpecDocument d) => SpecDocumentYaml.encode(
        document: d,
        tree: clashTree,
        modelVersion: '1.0',
      );
      expect(
        () => encode(SpecDocument()..setUnits('R', 'u_a')),
        throwsA(
          isA<SpecYamlFormatException>().having(
            (e) => e.message,
            'message',
            contains('also serializes as key `units`'),
          ),
        ),
      );
      expect(
        () => encode(
          SpecDocument()
            ..setFormField('R/SHP', 'units', '3')
            ..setUnits('R/SHP', 'u_a'),
        ),
        throwsA(
          isA<SpecYamlFormatException>().having(
            (e) => e.message,
            'message',
            contains('field literally named `units`'),
          ),
        ),
      );
    });

    test('a list item may not be keyed `units`', () {
      final d = SpecDocument();
      d.addListItem('DEMO/DLV-LST', sectionId: 'units');
      expect(() => enc(d), throwsA(isA<SpecYamlFormatException>()));
    });
  });

  test('applyMarkdownResult overwrites, clears and keeps units', () {
    final model = _corpusModel();
    final d = SpecDocument()
      ..setUnits('DEMO/TTL', 'stale')
      ..setUnits('DEMO/SUM', 'stale')
      ..setUnits('OTHER/kept', 'kept');
    const md =
        '# <!--[DEMO]--> Demo Document\n\n'
        '## <!--[TTL] units="u_a"--> Document Title\n\nHello\n';
    d.applyMarkdownResult(
      SpecDocumentMarkdown(model, SpecDocument()).parse(md),
    );
    expect(d.toJson()['units'], {'DEMO/TTL': 'u_a', 'OTHER/kept': 'kept'});
  });

  test('assembly merges units and refuses two fragments writing one', () {
    final a = SpecDocument()..setUnits('DEMO/TTL', 'u_a');
    final b = SpecDocument()..setUnits('DEMO/SUM', 'u_b');
    final ok = SpecDocument.assemble({'a': a, 'b': b});
    expect(ok.ok, isTrue);
    expect(ok.document!.units('DEMO/SUM'), 'u_b');
    final clash = SpecDocument.assemble({
      'a': a,
      'c': SpecDocument()..setUnits('DEMO/TTL', 'u_b'),
    });
    expect(clash.ok, isFalse);
    expect(clash.overlaps.single.store, 'units');
    expect(clash.overlaps.single.path, 'DEMO/TTL');
  });

  test('a review merge carries the units of an item a copy added', () {
    final model = _corpusModel();
    final base = SpecDocument();
    final first = base.addListItem('DEMO/items');
    base.setContent('$first/label', 'one');
    final copy = SpecDocument()..loadJson(base.toJson());
    final added = copy.addListItem('DEMO/items');
    copy
      ..setContent('$added/label', 'two')
      ..setUnits(added, 'u_a');
    const member = SpecReviewMember(
      memberId: 'alice',
      displayName: 'Alice',
      role: '',
    );
    final result = mergeReviews(
      base,
      [
        SpecReviewedCopy(
          memberId: 'alice',
          displayName: 'Alice',
          role: '',
          document: copy,
        ),
      ],
      SpecReviewMergeOptions(
        team: const [member],
        date: '2026-11-12',
        author: 'alice',
        model: model,
      ),
    );
    final merged = result.merged;
    final items = merged.listItems('DEMO/items');
    expect(items, hasLength(2));
    expect(merged.units(items.last), 'u_a');
  });

  group('validation phase 8', () {
    final model = _corpusModel();
    List<(String, String, String)> check(SpecDocument d) => [
      for (final e in validateDocument(model, d))
        (e.path, e.code.name, e.message),
    ];

    test('a declared unit on a routed section is clean', () {
      final d = _register()
        ..setUnits('DEMO/TTL', 'u_a')
        ..setUnits('DEMO/REG', 'u_a,u_b');
      expect(check(d), isEmpty);
    });

    test('unknownUnit names each undeclared id, in the order written', () {
      final d = _register()..setUnits('DEMO/TTL', 'u_x, u_a ,u_y');
      expect(check(d), [
        (
          'DEMO/TTL',
          'unknownUnit',
          'units names "u_x", which no generation unit declares',
        ),
        (
          'DEMO/TTL',
          'unknownUnit',
          'units names "u_y", which no generation unit declares',
        ),
      ]);
    });

    test('unitsUnrouted: a class reaching no @CodeSpecKind', () {
      final d = _register()
        ..setUnits('DEMO/META', 'u_a')
        ..setUnits('DEMO/META/tags', 'u_a')
        ..setUnits('DEMO/control', 'u_a')
        ..setUnits('DEMO/DLV-LST-1', 'u_a')
        // Routed: a field of a routed class, a list of a routed element.
        ..setUnits('DEMO/PRI', 'u_a')
        ..setUnits('DEMO/CARD-LST', 'u_a');
      const message =
          'units is set on a section that routes nothing to '
          'CodeSpecs';
      expect(check(d), [
        ('DEMO/DLV-LST-1', 'unitsUnrouted', message),
        ('DEMO/META', 'unitsUnrouted', message),
        ('DEMO/META/tags', 'unitsUnrouted', message),
        ('DEMO/control', 'unitsUnrouted', message),
      ]);
    });

    test('the register: duplicate, builds nothing, malformed area', () {
      final d = _register();
      final dup = d.addListItem('DEMO/DLV-LST');
      d.setFormField('$dup/content', 'unitId', 'u_a');
      d.setFormField('$dup/content', 'kind', 'server');
      // An item with no value at all is absence, not a finding.
      d.addListItem('DEMO/DLV-LST');
      for (final area in ['CE-DB', 'ce-db', 'CE-', 'CE-D1']) {
        final route = d.addListItem('DEMO/DLV-LST-1/DLR-LST');
        d.setFormField('$route/content', 'area', area);
        d.setFormField('$route/content', 'mapping', 'dart-tom');
      }
      expect(check(d), [
        (
          'DEMO/DLV-LST-1/DLR-LST-2',
          'unitAreaMalformed',
          'mapping area "ce-db" is not an area code (CE-…)',
        ),
        (
          'DEMO/DLV-LST-1/DLR-LST-3',
          'unitAreaMalformed',
          'mapping area "CE-" is not an area code (CE-…)',
        ),
        (
          'DEMO/DLV-LST-1/DLR-LST-4',
          'unitAreaMalformed',
          'mapping area "CE-D1" is not an area code (CE-…)',
        ),
        (
          'DEMO/DLV-LST-3',
          'duplicateUnitId',
          'generation unit "u_a" is declared twice',
        ),
        (
          'DEMO/DLV-LST-3',
          'unitBuildsNothing',
          'generation unit "u_a" builds neither a deploymentTarget nor a '
              'component',
        ),
      ]);
    });

    test('phase 8 follows the derived values and precedes annotations', () {
      final d = _register()
        ..setUnits('DEMO/TTL', 'u_x')
        ..setContent('DEMO/SUM', '> ⬆️ **C-1** a\n\n> ⬆️ **C-1** b');
      expect(validateDocument(model, d).map((e) => e.code.name), [
        'unknownUnit',
        'duplicateAnnotationId',
      ]);
    });
  });
}
