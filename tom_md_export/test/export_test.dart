// The export end to end: the readable header names the document links may
// use, a kind styles file replaces the built-in styles, and the fixture
// holding every construct compiles with Typst to a PDF — with the kind styles,
// with --no-kind-styles and with a styles file — through the library and
// through the `md_export` command. The compiling cases are skipped where no
// `typst` binary is found.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_md_export/tom_md_export.dart';

const fixture = 'test/fixtures/every_construct.readable.md';

Future<void> main() async {
  TypstCompiler? compiler;
  try {
    compiler = await TypstCompiler.find();
  } on TypstNotFound {
    compiler = null;
  }
  final noTypst = compiler == null ? 'no typst binary on this host' : null;

  late Directory scratch;
  setUp(() {
    final root = Directory('../../../ztmp')..createSync(recursive: true);
    scratch = root.createTempSync('tom_md_export_test_');
  });
  tearDown(() => scratch.deleteSync(recursive: true));

  group('markdownToTypst', () {
    test('a link to the rendition named in the readable header jumps', () {
      final t = markdownToTypst(
        File(fixture).readAsStringSync(),
        name: 'every_construct.readable.md',
      );
      expect(t, contains('#link(<TEXT>)[the document'));
      expect(t, contains('#link("other.tomspecs.md#X")'));
    });

    test('a kind styles file replaces the built-in styles', () {
      final styles = File(p.join(scratch.path, 'styles.typ'))
        ..writeAsStringSync('// my styles\n');
      final t = markdownToTypst(
        '# T',
        options: ExportOptions(kindStylesFile: styles.path),
      );
      expect(t, contains('// my styles'));
      expect(t, isNot(contains('tm-muted')));
    });
  });

  group('to PDF', () {
    Future<void> compiles(ExportOptions options) async {
      final out = p.join(scratch.path, 'out.pdf');
      final r = await exportMarkdownFile(
        fixture,
        output: out,
        options: options,
        compiler: compiler,
      );
      expect(r.ok, isTrue, reason: r.errors);
      expect(File(out).lengthSync(), greaterThan(1000));
      expect(File(r.typstFile).existsSync(), isFalse, reason: 'deleted');
    }

    test('every construct compiles with the kind styles', () async {
      await compiles(const ExportOptions());
    }, skip: noTypst);

    test('every construct compiles with the notation read as text', () async {
      await compiles(const ExportOptions(notation: false, outline: false));
    }, skip: noTypst);

    test('every construct compiles with a styles file of its own', () async {
      final styles = File(p.join(scratch.path, 'styles.typ'))
        ..writeAsStringSync(
          '#let tm-block(kind, body) = block(fill: luma(240), body)\n'
          '#let tm-span(kind, body) = emph(body)\n'
          '#let tm-cite(kind, arrow, body) = super[#arrow #body]\n',
        );
      await compiles(ExportOptions(kindStylesFile: styles.path));
    }, skip: noTypst);

    test('Typst failing keeps the source and reports it', () async {
      final styles = File(p.join(scratch.path, 'broken.typ'))
        ..writeAsStringSync('#let tm-block(kind, body = \n');
      final r = await exportMarkdownFile(
        fixture,
        output: p.join(scratch.path, 'out.pdf'),
        options: ExportOptions(kindStylesFile: styles.path),
        compiler: compiler,
      );
      expect(r.ok, isFalse);
      expect(File(r.typstFile).existsSync(), isTrue);
      expect(r.errors, isNotEmpty);
    }, skip: noTypst);
  });

  group('md_export', () {
    test('writes the PDF', () async {
      final out = p.join(scratch.path, 'cli.pdf');
      final o = StringBuffer();
      final code = await runMdExport([fixture, '-o', out], out: o, err: o);
      expect(code, 0, reason: '$o');
      expect(File(out).existsSync(), isTrue);
    }, skip: noTypst);

    test('--no-outline leaves the outline out', () async {
      final out = p.join(scratch.path, 'plain.pdf');
      final o = StringBuffer();
      await runMdExport(
        [fixture, '-o', out, '--typ-only', '--no-outline'],
        out: o,
        err: o,
      );
      final typ = File(p.join(scratch.path, 'plain.typ')).readAsStringSync();
      expect(typ, isNot(contains('#outline')));
    });

    test('--no-kind-styles writes the notation as text', () async {
      final out = p.join(scratch.path, 'text.pdf');
      final o = StringBuffer();
      await runMdExport(
        [fixture, '-o', out, '--typ-only', '--no-kind-styles'],
        out: o,
        err: o,
      );
      final typ = File(p.join(scratch.path, 'text.typ')).readAsStringSync();
      expect(typ, isNot(contains('#tm-')));
      expect(typ, contains(r'\:\:\: {\.records}'));
    });

    test('--typ-only writes the source and compiles nothing', () async {
      final out = p.join(scratch.path, 'src.pdf');
      final o = StringBuffer();
      final code = await runMdExport(
        [fixture, '-o', out, '--typ-only'],
        out: o,
        err: o,
      );
      expect(code, 0, reason: '$o');
      expect(File(p.join(scratch.path, 'src.typ')).existsSync(), isTrue);
      expect(File(out).existsSync(), isFalse);
    });

    test('usage errors exit 2', () async {
      final o = StringBuffer();
      expect(await runMdExport([], out: o, err: o), 2);
      expect(await runMdExport(['no_such.md'], out: o, err: o), 2);
      expect(
        await runMdExport(
          [fixture, '--kind-styles', fixture, '--no-kind-styles'],
          out: o,
          err: o,
        ),
        2,
      );
    });

    test('a typst that does not run is reported, exit 1', () async {
      final o = StringBuffer();
      final code = await runMdExport(
        [fixture, '--typst', p.join(scratch.path, 'no_typst')],
        out: o,
        err: o,
      );
      expect(code, 1);
      expect('$o', contains('does not run'));
    });
  });
}
