// Tests for the generic Markdown codec (`spec_document_markdown.dart`, step 4).
//
// The codec is the meta-data-driven Markdown half of the document load/save
// (§15.2): it renders the populated subtree of a root as a `<!-- docspec: -->`
// document (one heading per populated section, machine-readable section path as
// the first heading token, leaf values in fences widened past any backtick run)
// and parses that format back into the same path-keyed memory representation.
//
// Step-4 done-when (Markdown half): a document round-trips
// Markdown→memory→Markdown byte-stably for a fixture, including embedded
// verbatim bodies.

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

/// A class graph covering content, enum, `@Form`, a complex sub-section and a
/// list of complex items, so the round-trip exercises every store.
Map<String, dynamic> _sampleJson() => {
      'roots': [
        {
          'type': 'DemoDoc',
          'title': 'Demo Document',
          'sectionId': 'D00',
          'description': 'A demo document.',
        },
      ],
      'classes': {
        'DemoDoc': {
          'name': 'DemoDoc',
          'sectionId': 'D00',
          'fields': [
            {'name': 'overview', 'kind': 'content', 'sectionId': 'D00-OVR'},
            {
              'name': 'status',
              'kind': 'enum',
              'sectionId': 'D00-ST',
              'enumValues': ['draft', 'final'],
            },
            {
              'name': 'header',
              'kind': 'form',
              'sectionId': 'D00-HDR',
              'formFields': [
                {'name': 'author', 'label': 'Author', 'type': 'String'},
                {'name': 'reviewer', 'label': 'Reviewer', 'type': 'String'},
              ],
            },
            {
              'name': 'meta',
              'kind': 'complex',
              'type': 'DemoMeta',
              'sectionId': 'D00-MET',
            },
            {
              'name': 'items',
              'kind': 'list',
              'elementType': 'DemoItem',
              'elementIsComplex': true,
              'sectionId': 'D00-ITM',
            },
          ],
        },
        'DemoMeta': {
          'name': 'DemoMeta',
          'sectionId': 'D00-MET',
          'fields': [
            {'name': 'note', 'kind': 'content', 'sectionId': 'D00-MET-NOTE'},
          ],
        },
        'DemoItem': {
          'name': 'DemoItem',
          'fields': [
            {'name': 'label', 'kind': 'content', 'sectionId': 'D01-LBL'},
            {'name': 'body', 'kind': 'content', 'sectionId': 'D01-BODY'},
          ],
        },
      },
    };

/// A d4rt-flutter body that is multi-line and embeds a run of three backticks —
/// the case that forces the fenced-leaf encoder to widen its fence.
const _d4rtBody = 'Column(\n'
    '  children: [\n'
    '    Text("hi"),\n'
    '  ],\n'
    ') // not a fence: ``` still inside the body';

SpecDocument _populated() {
  final doc = SpecDocument()
    ..setContent('D00/D00-OVR', 'An overview paragraph.\nWith two lines.')
    ..setContent('D00/D00-ST', 'final')
    ..setFormField('D00/D00-HDR', 'author', 'Ada Lovelace')
    ..setContent('D00/D00-MET/D00-MET-NOTE', 'A note.');
  final item = doc.addListItem('D00/D00-ITM');
  doc.setContent('$item/D01-LBL', 'First item');
  doc.setContent('$item/D01-BODY', _d4rtBody);
  final item2 = doc.addListItem('D00/D00-ITM');
  doc.setContent('$item2/D01-LBL', 'Second item');
  return doc;
}

SpecModel _model() => SpecModel.fromJson(_sampleJson());

SpecRoot _root() => _model().roots.single;

void main() {
  group('export', () {
    test('emits a docspec header and section headings for populated nodes', () {
      final md = SpecDocumentMarkdown(_model(), _populated()).exportRoot(_root());
      expect(md, contains('<!-- docspec:'));
      expect(md, contains('# D00'));
      expect(md, contains('D00/D00-OVR'));
      expect(md, contains('D00/D00-HDR'));
      // Empty fields (e.g. the reviewer form field) are not emitted (sparse).
      expect(md, isNot(contains('reviewer')));
    });

    test('a content leaf with a backtick run is fenced wide enough to survive',
        () {
      final md = SpecDocumentMarkdown(_model(), _populated()).exportRoot(_root());
      expect(md, contains('````'));
    });
  });

  group('round-trip', () {
    test('export → parse into a fresh document reproduces every value', () {
      final md = SpecDocumentMarkdown(_model(), _populated()).exportRoot(_root());

      final target = SpecDocument();
      final codec = SpecDocumentMarkdown(_model(), target);
      final report = codec.parse(md);
      expect(report.isClean, isTrue, reason: report.rejections.toString());
      _applyInto(target, report);

      expect(target.content('D00/D00-OVR'),
          'An overview paragraph.\nWith two lines.');
      expect(target.content('D00/D00-ST'), 'final');
      expect(target.formField('D00/D00-HDR', 'author'), 'Ada Lovelace');
      expect(target.content('D00/D00-MET/D00-MET-NOTE'), 'A note.');
      final items = target.listItems('D00/D00-ITM');
      expect(items, hasLength(2));
      expect(target.content('${items[0]}/D01-LBL'), 'First item');
      // The embedded d4rt body survives verbatim, backticks and all.
      expect(target.content('${items[0]}/D01-BODY'), _d4rtBody);
      expect(target.content('${items[1]}/D01-LBL'), 'Second item');
    });

    test('Markdown → memory → Markdown is byte-stable for the fixture', () {
      final md1 = SpecDocumentMarkdown(_model(), _populated()).exportRoot(_root());

      final reloaded = SpecDocument();
      final report = SpecDocumentMarkdown(_model(), reloaded).parse(md1);
      _applyInto(reloaded, report);

      final md2 = SpecDocumentMarkdown(_model(), reloaded).exportRoot(_root());
      expect(md2, md1);
    });
  });

  group('parse-rejection protocol', () {
    test('an unknown section id is reported; valid siblings still parsed', () {
      const md = '<!-- docspec: d00/1 -->\n'
          '# D00 — Demo Document\n\n'
          '## D00/D00-OVR — overview\n'
          '```\nkept\n```\n\n'
          '## D00/D00-NOPE — bogus\n'
          '```\ndropped\n```\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(report.isClean, isFalse);
      expect(report.rejections.any((r) => r.anchor == 'D00/D00-NOPE'), isTrue);
      expect(report.content['D00/D00-OVR'], 'kept');
    });

    test('a fenced block with no owning section is reported as orphaned', () {
      const md = '<!-- docspec: d00/1 -->\n'
          '# D00 — Demo Document\n\n'
          '```\norphan body with no heading\n```\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(
        report.rejections
            .any((r) => r.reason == SpecMarkdownRejectReason.orphanBlock),
        isTrue,
      );
    });

    test('a form-field anchor under a non-form heading is a kind mismatch', () {
      const md = '<!-- docspec: d00/1 -->\n'
          '# D00 — Demo Document\n\n'
          '## D00/D00-OVR — overview\n'
          '<!-- field: author -->\n'
          '```\nmisplaced\n```\n';
      final report = SpecDocumentMarkdown(_model(), SpecDocument()).parse(md);
      expect(
        report.rejections
            .any((r) => r.reason == SpecMarkdownRejectReason.kindMismatch),
        isTrue,
      );
    });
  });
}

/// Applies a parsed [report] onto [target] (mirrors the controller's overwrite
/// for the covered scope), so the round-trip assertions read off a live
/// document.
void _applyInto(SpecDocument target, SpecMarkdownResult report) {
  // Recreate list items in path order so the `-N` seq matches the parsed paths.
  report.lists.forEach((listPath, spec) {
    final items = (spec['items'] as List).cast<String>();
    for (var n = 0; n < items.length; n++) {
      target.addListItem(listPath);
    }
  });
  report.content.forEach(target.setContent);
  report.forms.forEach((path, fields) {
    fields.forEach((f, v) => target.setFormField(path, f, v));
  });
}
