// Stripped renditions (SOM §11.10): heading divs, the readable header, the
// document strip's checks. The per-value rules are the conformance cases of
// `strip_cases.json`, run by conformance_test.dart (which also checks that
// every case's pieces put its input back).

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// A model nine sections deep: `L<n>` holds content `T<n>` and section
/// `L<n+1>`, so `T<n>` stands at depth n + 1.
SpecModel deepModel() {
  final classes = <String, Object?>{};
  for (var n = 1; n <= 9; n++) {
    classes['L$n'] = {
      'name': 'L$n',
      'sectionId': 'L$n',
      if (n == 1)
        'annotations': [
          {
            'name': 'Document',
            'arguments': {'title': 'Deep'},
          },
          {
            'name': 'SectionId',
            'arguments': {'id': 'L1'},
          },
        ],
      'fields': [
        {
          'name': 'text',
          'kind': 'content',
          'sectionId': 'T$n',
          'contentType': 'text',
        },
        if (n < 9)
          {
            'name': 'next',
            'kind': 'complex',
            'sectionId': 'L${n + 1}',
            'type': 'L${n + 1}',
          },
      ],
    };
  }
  return SpecModel.fromJson({
    'modelVersion': 1,
    'modelVersionLabel': '0.1.0+1',
    'roots': [
      {'type': 'L1', 'title': 'Deep', 'sectionId': 'L1'},
    ],
    'classes': classes,
  });
}

String pathTo(int n, {bool text = true}) =>
    [for (var k = 1; k <= n; k++) 'L$k', if (text) 'T$n'].join('/');

void main() {
  final model = deepModel();
  final root = model.rootByType('L1');

  SpecDocument deepDocument() {
    final doc = SpecDocument();
    for (var n = 1; n <= 9; n++) {
      doc.setContent(pathTo(n), 'Text $n [an aside]{.aside}.');
    }
    doc.setHeadline(pathTo(7, text: false), 'Seven & <more>\nsecond line');
    doc.setContent(
      pathTo(8),
      'Before.\n\n<div class="heading9" style="x">Not a heading</div>\n\n'
      '\\<div class="heading7" style="x">Escaped once</div>',
    );
    return doc;
  }

  group('styled-div headings (SOM §11.2)', () {
    test('sections deeper than level 6 are written as divs, and read back', () {
      final doc = deepDocument();
      final md = SpecDocumentMarkdown(
        model,
        doc,
        headingDivs: true,
      ).exportRoot(root);
      final lines = md.split('\n');
      expect(
        lines.where((l) => l.startsWith('#')).map((l) => l.split(' ')[0]),
        everyElement(hasLength(lessThanOrEqualTo(6))),
      );
      expect(
        lines,
        contains(
          '<div class="heading7" style="margin:1em 0 0.5em;padding-left:'
          '0.75em;font-weight:bold"><!--[L7]--> <a id="L7"></a> '
          'Seven &amp; &lt;more&gt;<br>second line</div>',
        ),
      );
      expect(
        lines.where((l) => l.startsWith('<div class="heading10"')).single,
        contains('padding-left:3em;'),
      );
      // A content line that would read as a heading div is escaped.
      expect(
        lines,
        contains(r'\<div class="heading9" style="x">Not a heading</div>'),
      );
      expect(
        lines,
        contains(r'\\<div class="heading7" style="x">Escaped once</div>'),
      );
      final back = SpecDocument.fromMarkdown(md, model);
      expect(back.result.rejections, isEmpty);
      expect(back.document.toJson(), doc.toJson());
    });

    test('without the option the same sections are # headings', () {
      final doc = deepDocument();
      final md = SpecDocumentMarkdown(model, doc).exportRoot(root);
      expect(md, isNot(contains('\n<div class="heading7"')));
      expect(md, contains('####### <!--[L7]-->'));
      expect(
        md,
        contains(r'\<div class="heading9" style="x">Not a heading</div>'),
      );
      expect(
        SpecDocument.fromMarkdown(md, model).document.toJson(),
        doc.toJson(),
      );
    });

    test('the indent grows by 0.75em a level', () {
      expect(
        [
          for (var d = 7; d <= 12; d++)
            SpecDocumentMarkdown.headingDivIndent(d),
        ],
        ['0.75', '1.5', '2.25', '3', '3.75', '4.5'],
      );
    });

    test('a heading6 div is content, a heading7 div a heading', () {
      expect(
        SpecDocumentMarkdown.headingDiv('<div class="heading6">x</div>'),
        isNull,
      );
      expect(
        SpecDocumentMarkdown.headingDiv(
          '<div class="heading7">a &amp;lt;</div>',
        ),
        (7, 'a &lt;'),
      );
    });
  });

  group('the readable rendition', () {
    const source = SpecReadableSource(
      file: 'deep.tomspecs.yaml',
      revision: 'r3',
      commit: '8e1d2a7',
      dirty: true,
    );

    test('the header follows the docspec line and round-trips', () {
      final r = SpecDocumentStrip.strip(
        deepDocument(),
        SpecStripOptions.fromNames(drop: ['aside'], headingDivs: true),
        model: model,
        source: source,
      );
      expect(r.findings, isEmpty);
      expect(
        r.readableHeader,
        '<!-- readable: drop=aside; headings=divs; '
        'of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->',
      );
      final lines = r.readable!.split('\n');
      expect(lines[0], startsWith('<!-- docspec: '));
      expect(lines[1], r.readableHeader);
      expect(r.readable, contains('<div class="heading8"'));
      expect(r.readable, isNot(contains('{.aside}')));

      final parsed = SpecDocumentMarkdown(
        model,
        SpecDocument(),
      ).parse(r.readable!);
      expect(parsed.readableHeader, r.readableHeader);
      final header = SpecReadableHeader.parse(parsed.readableHeader!)!;
      expect(header.format(), r.readableHeader);
      expect(header.options.drop, {'aside'});
      expect(header.options.headingDivs, isTrue);
      expect(header.source!.dirty, isTrue);
      expect(
        SpecDocument.fromMarkdown(r.readable!, model).document.toJson(),
        r.document.toJson(),
      );
    });

    test('the appendix lists the moved prose under its section titles', () {
      final r = SpecDocumentStrip.strip(
        deepDocument(),
        SpecStripOptions.fromNames(
          appendix: ['aside'],
          appendixReferences: true,
          headingDivs: true,
        ),
        model: model,
      );
      expect(r.findings, isEmpty);
      // T8 holds no aside: eight entries, one section each, in order.
      expect([for (final e in r.appendix) e.number], [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(
        [for (final e in r.appendix) e.value!.path],
        [
          for (var n = 1; n <= 9; n++)
            if (n != 8) pathTo(n),
        ],
      );
      final notes = r.readable!.split(
        '${SpecDocumentMarkdown.appendixMarker}\n',
      )[1];
      expect(notes, startsWith('\n## Notes\n'));
      expect('### Text\n'.allMatches(notes), hasLength(8));
      expect(
        notes,
        contains('<a id="note-1"></a>**[1]** an aside [↩](#note-1-ref)'),
      );
      expect(
        r.document.content(pathTo(1)),
        'Text 1<a id="note-1-ref"></a>[\\[1\\]](#note-1).',
      );
    });

    test('a value with a notation error is refused and reported', () {
      final doc = deepDocument()..setContent(pathTo(2), '::: {.aside}\nopen');
      final r = SpecDocumentStrip.strip(
        doc,
        SpecStripOptions.fromNames(drop: ['aside']),
        model: model,
      );
      expect(r.ok, isFalse);
      expect(r.findings.single.kind, 'notation');
      expect(r.document.content(pathTo(2)), '::: {.aside}\nopen');
    });

    test('without a model nothing is rendered or checked', () {
      final r = SpecDocumentStrip.strip(
        deepDocument(),
        SpecStripOptions.fromNames(drop: ['all']),
      );
      expect(r.readable, isNull);
      expect(r.document.content(pathTo(1)), 'Text 1.');
      expect(r.dropped, {'aside': 8});
    });
  });

  group('stripped() is the strip with drop: [comments]', () {
    test('headlines are stripped too', () {
      final doc = SpecDocument()
        ..setContent('L1/T1', 'Keep {++this++}.\n\n> ⬆️ **C-1** (Al): ok')
        ..setHeadline('L1/L2', 'Two {--old--}');
      final stripped = SpecReviewAnnotations(doc).stripped();
      expect(stripped.content('L1/T1'), 'Keep this.');
      expect(stripped.headline('L1/L2'), 'Two');
    });
  });
}
