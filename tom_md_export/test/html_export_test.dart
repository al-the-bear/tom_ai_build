// The HTML export and the edge cases of the clean export (G3-1), on the
// fixture holding every construct, in both outputs:
//
// - wide record tables wrapped in a smaller font;
// - kinds kept and shown in their style, unknown kinds as plain content;
// - review annotations kept (no -drop:comments) shown as text;
// - Mermaid blocks as code.
//
// The HTML cases run the MD Browser's renderer in Node and are skipped where
// Node or the extension checkout is not found; the PDF cases need Typst.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_md_export/tom_md_export.dart';

const fixture = 'test/fixtures/every_construct.readable.md';

Future<void> main() async {
  HtmlExporter? exporter;
  String? unavailable;
  try {
    exporter = await HtmlExporter.find();
  } on HtmlExportUnavailable catch (e) {
    unavailable = e.message;
  }

  late Directory scratch;
  setUpAll(() {
    final root = Directory('../../../ztmp')..createSync(recursive: true);
    scratch = root.createTempSync('tom_md_export_html_test_');
  });
  tearDownAll(() => scratch.deleteSync(recursive: true));

  Future<String> html({ExportOptions options = const ExportOptions()}) async {
    final out = p.join(scratch.path, 'page${options.notation}.html');
    final r = await exportMarkdownFileToHtml(
      fixture,
      output: out,
      options: options,
      exporter: exporter!,
    );
    expect(r.exitCode, 0, reason: r.errors);
    return File(out).readAsStringSync();
  }

  group('HTML', () {
    test('a standalone page carrying its stylesheet and title', () async {
      final h = await html();
      expect(h, startsWith('<!DOCTYPE html>'));
      expect(h, contains('<title>Every construct</title>'));
      expect(h, contains('details.tm-kind'));
      expect(h, contains('table.tm-wide'));
    }, skip: unavailable);

    test(
      'collapsed kinds are <details>, compact kinds their content',
      () async {
        final h = await html();
        for (final kind in ['provenance', 'editorial', 'aside']) {
          expect(h, contains('<details class="tm-kind" data-kind="$kind">'));
        }
        expect(h, contains('<div class="tm-kind" data-kind="records">'));
        expect(h, contains('<div class="tm-kind" data-kind="refs">'));
        expect(
          h,
          contains('<div class="tm-source">source: <a href="notes.md">'),
          reason: 'a provenance block links its source',
        );
      },
      skip: unavailable,
    );

    test('spans and the citation shapes in their style', () async {
      final h = await html();
      expect(h, contains('<span class="tm-span" data-kind="aside"'));
      expect(h, contains('<span class="tm-cite" data-kind="trace"'));
      expect(
        h,
        contains('title="extrapolated from iterations/sbpa21_notes.md"'),
      );
    }, skip: unavailable);

    test('an unknown kind is plain content', () async {
      final h = await html();
      expect(h, contains('Content of a kind the export does not know.'));
      expect(h, isNot(contains('data-kind="unknown-kind"')));
      expect(h, contains('an unknown span'));
      expect(h, isNot(contains('data-kind="custom"')));
    }, skip: unavailable);

    test('a wide record table is set smaller', () async {
      final h = await html();
      expect('<table class="tm-wide">'.allMatches(h), hasLength(1));
    }, skip: unavailable);

    test('review annotations kept are text', () async {
      final h = await html();
      expect(h, contains('{++added++}{@agent 2026-11-21T13:00+01:00}'));
      expect(h, contains('<blockquote>'));
    }, skip: unavailable);

    test('a Mermaid block is code', () async {
      final h = await html();
      expect(h, contains('<pre><code class="language-mermaid">graph TD'));
    }, skip: unavailable);

    test('links to the document itself stay within the page', () async {
      final h = await html();
      expect(h, contains('href="#TEXT"'));
      expect(h, isNot(contains('demo.tomspecs.md#')));
      expect(h, contains('href="other.tomspecs.md#X"'));
    }, skip: unavailable);

    test('with the notation read as text, no kinds stylesheet', () async {
      final h = await html(options: const ExportOptions(notation: false));
      expect(h, isNot(contains('<details')));
      expect(h, contains('::: {.records}'));
      expect(h, isNot(contains('details.tm-kind')));
    }, skip: unavailable);

    test('a kinds stylesheet of its own replaces the built-in one', () async {
      final css = File(p.join(scratch.path, 'kinds.css'))
        ..writeAsStringSync('/* my kinds */');
      final h = await html(options: ExportOptions(kindCssFile: css.path));
      expect(h, contains('/* my kinds */'));
      expect(h, isNot(contains('details.tm-kind')));
    }, skip: unavailable);

    test('md_export writes HTML for an .html output', () async {
      final out = p.join(scratch.path, 'cli.html');
      final o = StringBuffer();
      final code = await runMdExport([fixture, '-o', out], out: o, err: o);
      expect(code, 0, reason: '$o');
      expect(File(out).readAsStringSync(), contains('<details'));
    }, skip: unavailable);

    test('an extension checkout without the MD Browser is reported', () async {
      final o = StringBuffer();
      final code = await runMdExport(
        [fixture, '--format', 'html', '--md-browser', scratch.path],
        out: o,
        err: o,
      );
      expect(code, 1);
      expect('$o', contains('media/markdownBrowser/blocks.js'));
    }, skip: unavailable);
  });

  group('PDF (Typst source)', () {
    String typst() => markdownToTypst(File(fixture).readAsStringSync());

    test('a wide record table is set smaller, the others at 9pt', () {
      final t = typst();
      expect('#[#set text(size: 7.5pt);'.allMatches(t), hasLength(1));
      expect('#[#set text(size: 9pt);'.allMatches(t).length, greaterThan(1));
    });

    test('kinds styled, an unknown kind plain', () {
      final t = typst();
      expect(t, contains('#tm-block("records", ['));
      expect(t, contains('#tm-block("editorial", ['));
      expect(t, isNot(contains('"unknown-kind"')));
      expect(t, contains('Content of a kind the export does not know'));
    });

    test('review annotations kept are text; Mermaid is code', () {
      final t = typst();
      expect(t, contains(r'{\+\+added\+\+}'));
      expect(t, contains('#quote(block: true)['));
      expect(t, contains('#raw(block: true, lang: "mermaid", "graph TD'));
    });
  });
}
