// Tests for the generic YAML codec (`spec_document_yaml.dart`, step 4).
//
// The codec is the review-free half of the native `*.docspecs.yaml` format
// (§15.1): a header + `version:` (+ optional `modelVersion:`) followed by the
// `document:` pass written with self-verifying block scalars. The editor's
// `DocSpecsFile` composes its `review:` pass on top via the same machinery.
//
// Step-4 done-when (YAML half): a document round-trips YAML→memory→YAML
// byte-stably for a fixture, and the version stamp is preserved/written.

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// A document touching every store: content (incl. tricky multi-line / trailing
/// newline values), a `@Form`, and a list with a surviving seq counter.
SpecDocument _populated() {
  final doc = SpecDocument()
    ..setContent('D00/D00-OVR', 'line one\nline two\nline three')
    ..setContent('D00/D00-IND', '  indented first line\n    deeper')
    ..setContent('D00/D00-NL', 'ends with newline\n')
    ..setContent('D00/D00-NN', 'two trailing newlines\n\n') // JSON fallback
    ..setContent('D00/D00-CL', 'value: with: colons # and hash')
    ..setFormField('D00/D00-HDR', 'author', 'Ada Lovelace')
    ..setFormField('D00/D00-HDR', 'reviewer', 'Grace Hopper');
  final a = doc.addListItem('D00/D00-REQ'); // -1
  final b = doc.addListItem('D00/D00-REQ'); // -2
  doc.setContent('$a/text', 'first');
  doc.setContent('$b/text', 'second');
  doc.removeListItem(a); // seq stays 2; item -1 gone
  return doc;
}

void main() {
  group('encode', () {
    test('writes the format version and a block scalar for multi-line content',
        () {
      final doc = SpecDocument()..setContent('D00/D00-OVR', 'line one\nline two');
      final yaml = SpecDocumentYaml.encode(document: doc);
      expect(yaml, contains('version: ${SpecDocumentYaml.formatVersion}'));
      expect(yaml, contains('|2-'));
      expect(yaml, contains('line one'));
      expect(yaml, contains('line two'));
    });

    test('an empty document emits `document: {}` and no sub-sections', () {
      final yaml = SpecDocumentYaml.encode(document: SpecDocument());
      expect(yaml, contains('document: {}'));
      expect(yaml, isNot(contains('content:')));
      expect(yaml, isNot(contains('forms:')));
      expect(yaml, isNot(contains('lists:')));
    });

    test('the model-version stamp is written and omitted when absent', () {
      final stamped =
          SpecDocumentYaml.encode(document: SpecDocument(), modelVersion: '0.7');
      expect(stamped, contains('modelVersion: '));
      final plain = SpecDocumentYaml.encode(document: SpecDocument());
      expect(plain, isNot(contains('modelVersion:')));
    });
  });

  group('round-trip', () {
    test('YAML → memory → YAML is byte-stable for a populated fixture', () {
      final doc = _populated();
      final yaml1 = SpecDocumentYaml.encode(document: doc, modelVersion: '1.2');

      final loaded = SpecDocument()
        ..loadJson(SpecDocumentYaml.decode(yaml1).document);
      final yaml2 =
          SpecDocumentYaml.encode(document: loaded, modelVersion: '1.2');

      expect(yaml2, yaml1, reason: 're-encoding the reloaded document must '
          'reproduce the exact same bytes');
    });

    test('every value survives the round-trip verbatim', () {
      final doc = _populated();
      final yaml = SpecDocumentYaml.encode(document: doc);
      final out = SpecDocument()..loadJson(SpecDocumentYaml.decode(yaml).document);

      expect(out.content('D00/D00-OVR'), 'line one\nline two\nline three');
      expect(out.content('D00/D00-IND'), '  indented first line\n    deeper');
      expect(out.content('D00/D00-NL'), 'ends with newline\n');
      expect(out.content('D00/D00-NN'), 'two trailing newlines\n\n');
      expect(out.content('D00/D00-CL'), 'value: with: colons # and hash');
      expect(out.formField('D00/D00-HDR', 'author'), 'Ada Lovelace');
      expect(out.formField('D00/D00-HDR', 'reviewer'), 'Grace Hopper');
      expect(out.listItems('D00/D00-REQ'), ['D00/D00-REQ-2']);
      expect(out.content('D00/D00-REQ-2/text'), 'second');
      // The seq counter resumed from 2 → next add is -3 (never reusing -1/-2).
      expect(out.addListItem('D00/D00-REQ'), 'D00/D00-REQ-3');
    });

    test('the model-version stamp is preserved across decode', () {
      final yaml =
          SpecDocumentYaml.encode(document: _populated(), modelVersion: '2.5');
      expect(SpecDocumentYaml.decode(yaml).modelVersion, '2.5');
    });
  });

  group('decode tolerance', () {
    test('a missing document pass decodes as empty rather than throwing', () {
      final c = SpecDocumentYaml.decode('version: 1\n');
      expect(c.document, isEmpty);
      expect(c.review, isEmpty);
      expect(c.modelVersion, isNull);
    });

    test('an empty string decodes as empty', () {
      final c = SpecDocumentYaml.decode('');
      expect(c.document, isEmpty);
      expect(c.review, isEmpty);
    });

    test('the raw review pass is passed through untouched', () {
      const fixture = '''
version: 1
document: {}
review:
  "D00/a":
    scope: global
    stop_here: true
''';
      final c = SpecDocumentYaml.decode(fixture);
      expect(c.review.keys.map((k) => '$k'), contains('D00/a'));
    });
  });
}
