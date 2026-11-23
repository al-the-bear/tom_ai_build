// The long documents of the clean export (G3-1): Tom UAM's Information Model
// (about 146,000 lines readable) and Requirements Specification (about
// 32,000), each written as the stakeholder rendition — `tomspecs
// :spec-readable … -drop:all --heading-divs`, the first command of the
// documented sequence — and exported to PDF and to HTML within a stated time.
//
// The budgets are about four times what mbp measures (2026-11-23: IFM 22 s to
// PDF, 14 s to HTML; RSP 6 s and 1 s), so a slower host passes and a
// quadratic regression does not.
//
// Skipped where Tom UAM's checkout, the clitool, Typst or Node is missing.
@Timeout(Duration(minutes: 15))
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_md_export/tom_md_export.dart';

const _specs = '../../../tom_uam/tom_specs/phase3_detailed_specifications';
const _clitool = '../tom_specs_clitool';

const _budgets = {
  'ifm': (pdf: Duration(seconds: 120), html: Duration(seconds: 60)),
  'rsp': (pdf: Duration(seconds: 40), html: Duration(seconds: 15)),
};

Future<void> main() async {
  String? skip;
  TypstCompiler? typst;
  HtmlExporter? html;
  if (!Directory(_specs).existsSync()) {
    skip = "Tom UAM's checkout is not beside this workspace";
  } else if (!File(p.join(_clitool, 'bin', 'tomspecs.dart')).existsSync()) {
    skip = 'tom_specs_clitool is not beside this package';
  } else {
    try {
      typst = await TypstCompiler.find();
      html = await HtmlExporter.find();
    } on TypstNotFound catch (e) {
      skip = e.message;
    } on HtmlExportUnavailable catch (e) {
      skip = e.message;
    }
  }

  late Directory scratch;
  setUpAll(() {
    final root = Directory('../../../ztmp')..createSync(recursive: true);
    scratch = root.createTempSync('tom_md_export_long_test_');
  });
  tearDownAll(() => scratch.deleteSync(recursive: true));

  for (final doc in ['rsp', 'ifm']) {
    test(
      'the stripped tom_uam.$doc to PDF and HTML within its budget',
      () async {
        final readable = p.join(scratch.path, 'tom_uam.$doc.readable.md');
        final r = await Process.run(Platform.resolvedExecutable, [
          'run',
          'bin/tomspecs.dart',
          ':spec-readable',
          p.absolute(_specs, 'tom_uam.$doc.tomspecs.yaml'),
          p.absolute(readable),
          '-drop:all',
          '--heading-divs',
        ], workingDirectory: _clitool);
        expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
        final text = File(readable).readAsStringSync();
        expect(text, startsWith('<!-- docspec:'));
        expect(text, contains('<!-- readable: drop='));

        final pdfWatch = Stopwatch()..start();
        final pdf = await exportMarkdownFile(
          readable,
          output: p.join(scratch.path, 'tom_uam.$doc.pdf'),
          compiler: typst,
        );
        pdfWatch.stop();
        expect(pdf.ok, isTrue, reason: pdf.errors);
        expect(File(pdf.pdfFile!).lengthSync(), greaterThan(1000000));
        expect(
          pdfWatch.elapsed,
          lessThan(_budgets[doc]!.pdf),
          reason: 'PDF took ${pdfWatch.elapsed}',
        );

        final htmlWatch = Stopwatch()..start();
        final page = await exportMarkdownFileToHtml(
          readable,
          output: p.join(scratch.path, 'tom_uam.$doc.html'),
          exporter: html!,
        );
        htmlWatch.stop();
        expect(page.exitCode, 0, reason: page.errors);
        expect(File(page.output).lengthSync(), greaterThan(1000000));
        expect(
          htmlWatch.elapsed,
          lessThan(_budgets[doc]!.html),
          reason: 'HTML took ${htmlWatch.elapsed}',
        );
        printOnFailure(
          'tom_uam.$doc: PDF ${pdfWatch.elapsed}, HTML ${htmlWatch.elapsed}',
        );
      },
      skip: skip,
    );
  }
}
