// Tests for the hierarchical `*.docspecs.yaml` v2 codec (DR5).
//
// The codec walks the document root's SomMetaTree: sections nest, keys are
// `<section-id> <member-name>`, list items key by stored section id (or an
// anonymous positional `<member>-<n>`), body text uses the literal `content`
// key, and form fields use their bare names. Round-trip is lossless modulo
// the DR1 §2.4.3 empty-line dedup; version-1 files and unmatched keys are
// structured load errors.

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// A SYNTHETIC codec-exerciser — NOT a model-convention reference.
///
/// This fixture deliberately covers the codec's full field-kind matrix so the
/// round-trip logic is tested end to end: root body content, a content section
/// with a nested complex section, a complex list with `@SectionIdPattern`,
/// a scalar list, a `@Form` with a numeric field, an enum, and an int scalar.
///
/// Several shapes here do NOT occur in the real `tom_specs_model` and must not
/// be read as conventions to imitate:
///   * `count` (kind `scalar`, type `int`) — the real model has ZERO non-String
///     primitive leaves;
///   * id-less `content` leaves (`Control.owner`, `Scope.outOfScope`,
///     `Requirement.text`) — real content leaves carry a field- or class-level
///     `@SectionId`;
///   * `Control` — a class with TWO `content` leaves (`summary` + `owner`); real
///     classes have exactly one `content` body.
/// They exist only to force the codec down the id-fallback and multi-content
/// branches. For a fixture that mirrors real-model conventions, see
/// [_realisticModel] below.
SpecModel _model() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'Demo', 'title': 'Demo Document', 'sectionId': 'D00'},
      ],
      'classes': {
        'Demo': {
          'name': 'Demo',
          'sectionId': 'D00',
          'fields': [
            {
              'name': 'overview',
              'kind': 'content',
              'sectionId': 'D00-OVR',
              'serializationOrder': 0,
            },
            {
              'name': 'scope',
              'kind': 'complex',
              'sectionId': 'D00-SCO',
              'type': 'Scope',
              'serializationOrder': 1,
            },
            {
              'name': 'header',
              'kind': 'form',
              'sectionId': 'D00-HDR',
              'serializationOrder': 2,
              'formFields': [
                {'name': 'author', 'label': 'Author', 'type': 'String'},
                {'name': 'reviewer', 'label': 'Reviewer', 'type': 'String'},
                {'name': 'revision', 'label': 'Revision', 'type': 'int'},
              ],
            },
            {
              'name': 'requirements',
              'kind': 'list',
              'sectionId': 'D00-REQ',
              'sectionIdPattern': 'REQ-xxx',
              'elementType': 'Requirement',
              'elementIsComplex': true,
              'serializationOrder': 3,
            },
            {
              'name': 'tags',
              'kind': 'list',
              'sectionId': 'D00-TAG',
              'elementType': 'String',
              'elementIsComplex': false,
              'serializationOrder': 4,
            },
            {
              'name': 'priority',
              'kind': 'enum',
              'sectionId': 'D00-PRI',
              'enumType': 'Priority',
              'enumValues': ['low', 'high'],
              'serializationOrder': 5,
            },
            {
              'name': 'count',
              'kind': 'scalar',
              'type': 'int',
              'serializationOrder': 6,
            },
            {
              // A section whose @SectionId lives on the TARGET CLASS only
              // (the SBP pattern): the field carries no id, so its key must
              // fall back to Control's `CTRL` (DR1 §2.2 field-id-else-class-id).
              'name': 'control',
              'kind': 'complex',
              'type': 'Control',
              'serializationOrder': 7,
            },
          ],
        },
        'Control': {
          'name': 'Control',
          'sectionId': 'CTRL',
          'fields': [
            {'name': 'summary', 'kind': 'content', 'sectionId': 'CTRL-SUM'},
            {'name': 'owner', 'kind': 'content'},
          ],
        },
        'Scope': {
          'name': 'Scope',
          'fields': [
            {'name': 'inScope', 'kind': 'content', 'sectionId': 'D00-INS'},
            {'name': 'outOfScope', 'kind': 'content'},
          ],
        },
        'Requirement': {
          'name': 'Requirement',
          'fields': [
            {'name': 'text', 'kind': 'content'},
            {
              'name': 'notes',
              'kind': 'list',
              'elementType': 'String',
              'elementIsComplex': false,
            },
          ],
        },
      },
    });

/// A REALISTIC fixture mirroring the conventions of the real `tom_specs_model`.
///
/// Unlike [_model] (a synthetic codec-exerciser), every shape here follows the
/// canonical DR1 §6.1a conventions so it can serve as a convention reference:
///   * exactly one `content` body leaf per class, and it carries a field-level
///     `@SectionId`;
///   * every non-content field carries a field-level `@SectionId`;
///   * a `@Form` group for structured header metadata;
///   * `@Reference` leaves modelled as `content` String fields with a field-level
///     `@SectionId` and a captured `Reference` annotation (the real model has no
///     dedicated reference kind — a reference is a String leaf plus the marker);
///   * NO `int`/non-String scalar leaves.
SpecModel _realisticModel() => SpecModel.fromJson({
      'modelVersion': 1,
      'roots': [
        {'type': 'Plan', 'title': 'Plan Document', 'sectionId': 'P00'},
      ],
      'classes': {
        'Plan': {
          'name': 'Plan',
          'sectionId': 'P00',
          'fields': [
            {
              'name': 'overview',
              'kind': 'content',
              'sectionId': 'P00-OVR',
              'serializationOrder': 0,
            },
            {
              'name': 'header',
              'kind': 'form',
              'sectionId': 'P00-HDR',
              'serializationOrder': 1,
              'formFields': [
                {'name': 'author', 'label': 'Author', 'type': 'String'},
                {'name': 'status', 'label': 'Status', 'type': 'String'},
              ],
            },
            {
              'name': 'owner',
              'kind': 'content',
              'sectionId': 'P00-OWN',
              'serializationOrder': 2,
              'annotations': [
                {
                  'name': 'Reference',
                  'arguments': {'target': 'Party'},
                },
              ],
            },
            {
              'name': 'requirements',
              'kind': 'list',
              'sectionId': 'P00-REQ',
              'sectionIdPattern': 'REQ-xxx',
              'elementType': 'Requirement',
              'elementIsComplex': true,
              'serializationOrder': 3,
            },
          ],
        },
        'Requirement': {
          'name': 'Requirement',
          'sectionId': 'REQ',
          'fields': [
            {
              'name': 'description',
              'kind': 'content',
              'sectionId': 'REQ-DSC',
              'serializationOrder': 0,
            },
            {
              'name': 'priority',
              'kind': 'enum',
              'sectionId': 'REQ-PRI',
              'enumType': 'Priority',
              'enumValues': ['low', 'high'],
              'serializationOrder': 1,
            },
            {
              'name': 'relatedTo',
              'kind': 'content',
              'sectionId': 'REQ-REL',
              'serializationOrder': 2,
              'annotations': [
                {
                  'name': 'Reference',
                  'arguments': {'target': 'Requirement'},
                },
              ],
            },
          ],
        },
      },
    });

SomMetaTree _tree() => buildSomMetaTree(_model());

/// A populated document touching every store and the §2.4 edge cases.
SpecDocument _populated() {
  final doc = SpecDocument()
    ..setContent('D00', 'Preamble body text.')
    ..setContent('D00/D00-OVR', 'line one\nline two\nline three')
    ..setContent('D00/D00-SCO/D00-INS', '  indented first line\n    deeper')
    ..setContent('D00/D00-SCO/outOfScope', 'ends with newline\n')
    ..setContent('D00/D00-PRI', 'high')
    ..setContent('D00/count', '3')
    ..setFormField('D00/D00-HDR', 'author', 'Ada Lovelace')
    ..setFormField('D00/D00-HDR', 'reviewer', 'Grace Hopper')
    ..setFormField('D00/D00-HDR', 'revision', '7');
  final a = doc.addListItem('D00/D00-REQ', sectionId: 'REQ-AB1');
  doc.setContent('$a/text', 'value: with: colons # and hash');
  final n1 = doc.addListItem('$a/notes');
  doc.setContent(n1, 'a nested scalar note');
  final b = doc.addListItem('D00/D00-REQ'); // anonymous item
  doc.setContent('$b/text', 'second requirement');
  final t1 = doc.addListItem('D00/D00-TAG');
  doc.setContent(t1, 'alpha');
  return doc;
}

void main() {
  final tree = _tree();

  String enc(SpecDocument d, {String? stamp}) =>
      SpecDocumentYaml.encode(document: d, tree: tree, modelVersion: stamp);
  SpecYamlContents dec(String yaml) => SpecDocumentYaml.decode(yaml, tree);
  SpecDocument roundTrip(SpecDocument d) => dec(enc(d)).document;

  group('encode', () {
    test('writes the v2 header, version and hierarchical structure', () {
      final yaml = enc(_populated(), stamp: '1.0');
      expect(yaml, startsWith('# TomSpecs document (*.docspecs.yaml). '
          'Hierarchical format v2.\n'));
      expect(yaml, contains('version: 2\n'));
      expect(yaml, contains('modelVersion: "1.0"\n'));
      expect(yaml, contains('\ndocument:\n  D00 Demo:\n'));
      // Nesting mirrors structure: scope section nests its fields.
      expect(yaml, contains('\n    D00-SCO scope:\n      D00-INS inScope:'));
      // Root body text uses the literal `content` key.
      expect(yaml, contains('\n    content: |2-\n      Preamble body text.\n'));
      // List items: stored id and anonymous positional key.
      expect(yaml, contains('\n    D00-REQ requirements:\n      REQ-AB1:\n'));
      expect(yaml, contains('\n      requirements-2:\n'));
      // No flat path maps anywhere.
      expect(yaml, isNot(contains('"D00/')));
    });

    test('sibling order follows @SerializationOrder, sparse emission', () {
      final doc = SpecDocument()
        ..setContent('D00/D00-PRI', 'low') // order 5
        ..setContent('D00/D00-OVR', 'first'); // order 0
      final yaml = enc(doc);
      expect(yaml.indexOf('D00-OVR overview:'),
          lessThan(yaml.indexOf('D00-PRI priority:')));
      expect(yaml, isNot(contains('D00-SCO'))); // unpopulated → absent
    });

    test('non-text values are plain scalars (§2.5)', () {
      final yaml = enc(_populated());
      expect(yaml, contains('\n    D00-PRI priority: high\n'));
      expect(yaml, contains('\n    count: 3\n'));
      expect(yaml, contains('\n      revision: 7\n'));
    });

    test('YAML 1.1-special values are quoted, not plain (§2.5, DRC6)', () {
      // `on`/`no` are YAML 1.1-only booleans and `1:30` is a 1.1 sexagesimal
      // int: all three parse as plain strings under YAML 1.2 (Dart) but as
      // bool/number under YAML 1.1 (e.g. PyYAML). They must be emitted as
      // block scalars so a 1.1 parser reads them back as the exact string; an
      // ordinary token still emits plainly.
      final doc = SpecDocument();
      for (final v in ['on', 'no', '1:30', 'plain']) {
        doc.setContent(doc.addListItem('D00/D00-TAG'), v);
      }
      final yaml = enc(doc);
      // Specials become literal block scalars (unambiguous strings in 1.1/1.2).
      expect(yaml, contains('\n      tags-1: |2-\n        on\n'));
      expect(yaml, contains('\n      tags-2: |2-\n        no\n'));
      expect(yaml, contains('\n      tags-3: |2-\n        1:30\n'));
      // A non-special token stays plain.
      expect(yaml, contains('\n      tags-4: plain\n'));
      // And every value survives the round-trip verbatim.
      final out = roundTrip(doc);
      expect(out.listItems('D00/D00-TAG').map(out.content),
          ['on', 'no', '1:30', 'plain']);
    });

    test('a section whose id is class-level renders the class id as its key '
        '(DR1 §2.2 field-id-else-class-id)', () {
      final doc = SpecDocument()
        ..setContent('D00/control/CTRL-SUM', 'controlled summary')
        ..setContent('D00/control/owner', 'the owner');
      final yaml = enc(doc);
      // `control` carries no field-level @SectionId, so the key falls back to
      // the target class Control's id (`CTRL`) — the markdown heading rule.
      expect(yaml, contains('\n    CTRL control:\n'));
      expect(yaml, contains('\n      CTRL-SUM summary:'));
      // A content leaf without any id stays bare (no class fallback here).
      expect(yaml, contains('\n      owner:'));
      // Decode is symmetric: the class-id key round-trips to the field path,
      // and the path segment (`control`) is unchanged by the key fallback.
      final out = roundTrip(doc);
      expect(out.content('D00/control/CTRL-SUM'), 'controlled summary');
      expect(out.content('D00/control/owner'), 'the owner');
    });

    test('an empty document emits `document: {}`', () {
      final yaml = enc(SpecDocument());
      expect(yaml, contains('document: {}'));
    });

    test('the model-version stamp is omitted when absent', () {
      expect(enc(SpecDocument()), isNot(contains('modelVersion:')));
    });

    test('values the tree cannot place are a structured error', () {
      final doc = SpecDocument()..setContent('D00/ghost', 'x');
      expect(() => enc(doc), throwsA(isA<SpecYamlFormatException>()));
    });

    test('an unknown form field is a structured error', () {
      final doc = SpecDocument()..setFormField('D00/D00-HDR', 'bogus', 'v');
      expect(() => enc(doc), throwsA(isA<SpecYamlFormatException>()));
    });
  });

  group('round-trip', () {
    test('every value survives verbatim', () {
      final out = roundTrip(_populated());
      expect(out.content('D00'), 'Preamble body text.');
      expect(out.content('D00/D00-OVR'), 'line one\nline two\nline three');
      expect(out.content('D00/D00-SCO/D00-INS'),
          '  indented first line\n    deeper');
      expect(out.content('D00/D00-SCO/outOfScope'), 'ends with newline\n');
      expect(out.content('D00/D00-PRI'), 'high');
      expect(out.content('D00/count'), '3');
      expect(out.formField('D00/D00-HDR', 'author'), 'Ada Lovelace');
      expect(out.formField('D00/D00-HDR', 'reviewer'), 'Grace Hopper');
      expect(out.formField('D00/D00-HDR', 'revision'), '7');
      expect(out.listItemCount('D00/D00-REQ'), 2);
      final items = out.listItems('D00/D00-REQ');
      expect(out.itemSectionId(items[0]), 'REQ-AB1');
      expect(out.itemSectionId(items[1]), isNull); // anonymous stays anonymous
      expect(out.content('${items[0]}/text'), 'value: with: colons # and hash');
      expect(out.content('${items[1]}/text'), 'second requirement');
      final notes = out.listItems('${items[0]}/notes');
      expect(notes, hasLength(1));
      expect(out.content(notes.first), 'a nested scalar note');
      final tags = out.listItems('D00/D00-TAG');
      expect(out.content(tags.single), 'alpha');
    });

    test('encode is byte-stable across decode → re-encode', () {
      final yaml1 = enc(_populated(), stamp: '1.2');
      final yaml2 = SpecDocumentYaml.encode(
          document: dec(yaml1).document, tree: tree, modelVersion: '1.2');
      expect(yaml2, yaml1);
    });

    test('the model-version stamp lands on the decoded document', () {
      final decoded = dec(enc(_populated(), stamp: '2.5'));
      expect(decoded.modelVersion, '2.5');
      expect(decoded.document.modelVersion, '2.5');
    });

    test('markdown edge cases survive (leading/trailing blanks, tabs, YAML '
        'specials, 2+ trailing newlines via JSON fallback)', () {
      final cases = <String>[
        '\nleading blank line',
        'trailing blank line kept as one\n\nend',
        'two trailing newlines\n\n', // block cannot represent → JSON fallback
        'trailing space on a line \nnext',
        '\ttab\tpreserved',
        '- looks: like\n  yaml: [a, b]\n# comment-ish',
        '"double" and \'single\' quotes',
        'ends with newline\n',
        '   only-indentation-sensitive\n      nested deeper\n   back',
      ];
      for (var i = 0; i < cases.length; i++) {
        final doc = SpecDocument()..setContent('D00/D00-OVR', cases[i]);
        final out = roundTrip(doc);
        expect(out.content('D00/D00-OVR'), cases[i], reason: 'case #$i');
      }
    });

    test('runs of 2+ empty lines collapse to one on write (§2.4.3)', () {
      final doc = SpecDocument()
        ..setContent('D00/D00-OVR', 'a\n\n\n\nb\n\n\nc');
      expect(roundTrip(doc).content('D00/D00-OVR'), 'a\n\nb\n\nc');
    });

    test('an empty complex list item round-trips as `{}`', () {
      final doc = SpecDocument()..addListItem('D00/D00-REQ');
      final yaml = enc(doc);
      expect(yaml, contains('requirements-1: {}'));
      expect(roundTrip(doc).listItemCount('D00/D00-REQ'), 1);
    });
  });

  group('strict decode', () {
    test('version 1 files are rejected with a clear error', () {
      expect(
          () => dec('version: 1\ndocument: {}\n'),
          throwsA(isA<SpecYamlFormatException>().having(
              (e) => e.message, 'message', contains('version 1'))));
    });

    test('a missing version is rejected', () {
      expect(() => dec('document: {}\n'),
          throwsA(isA<SpecYamlFormatException>()));
      expect(() => dec(''), throwsA(isA<SpecYamlFormatException>()));
    });

    test('an unmatched key is a structured load error, not a silent skip', () {
      const bad = 'version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n'
          '      x\n';
      expect(
          () => dec(bad),
          throwsA(isA<SpecYamlFormatException>().having(
              (e) => e.message, 'message', contains('nonsense'))));
    });

    test('a wrong root key is a structured load error', () {
      const bad = 'version: 2\ndocument:\n  WRONG Other: {}\n';
      expect(() => dec(bad), throwsA(isA<SpecYamlFormatException>()));
    });

    test('an unknown form field on read is a structured load error', () {
      const bad = 'version: 2\ndocument:\n  D00 Demo:\n'
          '    D00-HDR header:\n      bogus: |-\n        v\n';
      expect(() => dec(bad), throwsA(isA<SpecYamlFormatException>()));
    });

    test('a missing/empty document pass decodes as an empty document', () {
      expect(dec('version: 2\n').document.isEmpty, isTrue);
      expect(dec('version: 2\ndocument: {}\n').document.isEmpty, isTrue);
    });

    test('the raw review pass is passed through untouched', () {
      const fixture = '''
version: 2
document: {}
review:
  "D00/a":
    scope: global
''';
      final c = dec(fixture);
      expect(c.review.keys.map((k) => '$k'), contains('D00/a'));
    });
  });

  // A convention-conformant fixture (single content body per class, field-level
  // @SectionId everywhere, @Form groups, @Reference String leaves, no int
  // scalars). It exists so the codec is exercised against a shape that actually
  // occurs in the real tom_specs_model — not just the [_model] kind-matrix.
  group('realistic (convention-conformant) model', () {
    final realTree = buildSomMetaTree(_realisticModel());
    String encReal(SpecDocument d) =>
        SpecDocumentYaml.encode(document: d, tree: realTree);
    SpecDocument roundTripReal(SpecDocument d) =>
        SpecDocumentYaml.decode(encReal(d), realTree).document;

    test('every field-level @SectionId keys its section, @Reference leaves '
        'behave as plain content', () {
      final doc = SpecDocument()
        ..setContent('P00/P00-OVR', 'the overview body')
        ..setContent('P00/P00-OWN', 'Party/ACME') // @Reference leaf
        ..setFormField('P00/P00-HDR', 'author', 'Ada')
        ..setFormField('P00/P00-HDR', 'status', 'draft');
      final r = doc.addListItem('P00/P00-REQ', sectionId: 'REQ-001');
      doc
        ..setContent('$r/REQ-DSC', 'requirement text')
        ..setContent('$r/REQ-PRI', 'high')
        ..setContent('$r/REQ-REL', 'Requirement/REQ-000'); // @Reference leaf
      final yaml = encReal(doc);
      // Field-level ids drive every key (no class-id fallback needed here).
      expect(yaml, contains('\n    P00-OVR overview:'));
      expect(yaml, contains('\n    P00-OWN owner:'));
      expect(yaml, contains('\n    P00-HDR header:\n'));
      expect(yaml, contains('\n    P00-REQ requirements:\n      REQ-001:\n'));
      expect(yaml, contains('\n        REQ-REL relatedTo:'));
      // Round-trip is lossless including the @Reference String leaves.
      final out = roundTripReal(doc);
      expect(out.content('P00/P00-OVR'), 'the overview body');
      expect(out.content('P00/P00-OWN'), 'Party/ACME');
      expect(out.formField('P00/P00-HDR', 'status'), 'draft');
      final items = out.listItems('P00/P00-REQ');
      expect(out.itemSectionId(items.single), 'REQ-001');
      expect(out.content('${items.single}/REQ-DSC'), 'requirement text');
      expect(out.content('${items.single}/REQ-REL'), 'Requirement/REQ-000');
    });
  });
}
