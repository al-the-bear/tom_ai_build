/// A generated skeleton must validate against the schema it was generated from.
///
/// Two divergences made it not:
///
/// * the first document section was emitted at level 1, and the scanner reads a
///   level-1 heading as the document *title* — so the section vanished and was
///   then reported missing. A skeleton is meant to start a document in the
///   right shape, not to be corrected into one.
/// * headings were named and identified from the schema's section KEY, ignoring
///   `access-key`, and the id concatenated prefix + key without noticing the key
///   already began with the prefix — so a section keyed `note-001` under prefix
///   `note` came out as `[note-note-001] Note 001`.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';

DocSpecSchema _schema(Map<String, dynamic> yaml, {String id = 'skel'}) =>
    DocSpecSchema.fromYaml(yaml, id: id, version: '1.0');

/// One required section of type `note` (prefix `note`), keyed [key].
DocSpecSchema _oneSection({required String key, String? accessKey}) => _schema({
  'section-types': {
    'note': {'prefix': 'note'},
  },
  'document': {
    'sections': {
      key: {'section-type': 'note', 'access-key': ?accessKey},
    },
  },
});

/// Writes [schema] and a skeleton generated from it into a temp directory,
/// then scans the skeleton back with that schema resolvable.
SpecDoc _roundTrip(DocSpecSchema schema, String schemaYaml) {
  final dir = Directory.systemTemp.createTempSync('skel_shape_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final schemas = Directory('${dir.path}/schemas')..createSync();
  File(
    '${schemas.path}/${schema.id}.${schema.version}.docspecs-schema.yaml',
  ).writeAsStringSync(schemaYaml);
  final md = File('${dir.path}/skeleton.md')
    ..writeAsStringSync(DocSpecsSkeletonGenerator.generate(schema));
  return DocSpecs.scanDocumentSync(
    filePath: md.path,
    schemaFolder: schemas.path,
    workspaceRoot: dir.path,
  );
}

void main() {
  group('SKS1: the skeleton has a title and sections beneath it', () {
    test('the level-1 heading is a title, not the first section', () {
      final md = DocSpecsSkeletonGenerator.generate(
        _oneSection(key: 'overview'),
      );
      final headings = md.split('\n').where((l) => l.startsWith('#')).toList();
      expect(headings, hasLength(2), reason: 'a title and one section');
      expect(headings[0], startsWith('# '));
      expect(
        headings[0],
        isNot(contains('[')),
        reason: 'a title carries no section id',
      );
      expect(headings[1], startsWith('## '));
    });

    test('the title is derived from the schema id', () {
      // The schema model carries no title field, so the id is the only source
      // that says anything; it is a placeholder an author replaces.
      final md = DocSpecsSkeletonGenerator.generate(
        _oneSection(key: 'overview'),
      );
      expect(md, contains('# Skel\n'));
    });

    test('generate -> scan -> validate yields no errors', () {
      // The whole point of the generator: the document it produces is already
      // in the shape the validator accepts.
      final doc = _roundTrip(_oneSection(key: 'overview'), '''
section-types:
  note:
    prefix: note

document:
  sections:
    overview:
      section-type: note
''');
      expect(doc.wasValidated, isTrue, reason: 'a vacuous pass is not a pass');
      expect(doc.validationErrors, isEmpty);
    });
  });

  group('SKS2: heading names and ids', () {
    test('a key already carrying the prefix is not prefixed twice', () {
      final md = DocSpecsSkeletonGenerator.generate(
        _oneSection(key: 'note-001'),
      );
      expect(md, contains('[note-001]'));
      expect(md, isNot(contains('[note-note-001]')));
    });

    test('a key without the prefix gets one', () {
      final md = DocSpecsSkeletonGenerator.generate(
        _oneSection(key: 'overview'),
      );
      expect(md, contains('[note-overview]'));
    });

    test('access-key names the heading when present', () {
      final md = DocSpecsSkeletonGenerator.generate(
        _oneSection(key: 'note-001', accessKey: 'overview'),
      );
      expect(md, contains('[note-001] Overview'));
    });

    test('without access-key the key names the heading', () {
      final md = DocSpecsSkeletonGenerator.generate(
        _oneSection(key: 'overview'),
      );
      expect(md, contains('[note-overview] Overview'));
    });

    test('an access-keyed section still round-trips clean', () {
      final doc = _roundTrip(
        _oneSection(key: 'note-001', accessKey: 'overview'),
        '''
section-types:
  note:
    prefix: note

document:
  sections:
    note-001:
      section-type: note
      access-key: overview
''',
      );
      expect(doc.validationErrors, isEmpty);
    });
  });
}
