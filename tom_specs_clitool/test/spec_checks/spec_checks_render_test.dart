// Tests of the `render` check (`tomspecs :spec-readable`,
// lib/src/spec_checks_cli.dart): the readable rendition and the merge of an
// edited one back onto the document (SOM §11.10), with its usage errors, the
// dry run and `--write`.
//
// The shipped Meridian Solution Blueprint (tom_som_dart_v0/documents/) is the
// document; each test copies it into a scratch folder of its own under the
// workspace's ztmp/, which git ignores, so a readable header carries no commit.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/spec_checks_cli.dart';

const _meridian =
    '../tom_som_dart_v0/documents/meridian_order_management.tomspecs.yaml';

/// A sentence of one value (the order-capture requirement's description).
const _edi = 'The system must accept orders from the wholesale EDI adapter';

/// A sentence of another value (the pricing requirement's description).
const _pricing = 'Pricing must be computed synchronously';

/// The citation the setUp writes into the [_edi] value.
const _cite = '(-> C2.1)';

/// A sink collecting what a run writes.
class _Capture {
  final _out = _Sink(), _err = _Sink();
  String get out => _out.text;
  String get err => _err.text;
  int run(List<String> args) => runSpecChecks(args, out: _out, err: _err);
}

class _Sink implements IOSink {
  final _buffer = StringBuffer();
  String get text => _buffer.toString();
  @override
  Encoding encoding = utf8;
  @override
  void write(Object? object) => _buffer.write(object);
  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);
  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      _buffer.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);
  @override
  void add(List<int> data) => _buffer.write(utf8.decode(data));
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> get done async {}
  @override
  Future<void> flush() async {}
}

/// [path]'s text with [from] replaced once by [to]; the text must hold it.
void _replaceIn(String path, String from, String to) {
  final text = File(path).readAsStringSync();
  expect(text, contains(from), reason: '$path holds «$from»');
  File(path).writeAsStringSync(text.replaceFirst(from, to));
}

/// The lines that differ between two texts of the same line count.
List<int> _changedLines(String a, String b) {
  final x = a.split('\n'), y = b.split('\n');
  expect(y.length, x.length);
  return [
    for (var i = 0; i < x.length; i++)
      if (x[i] != y[i]) i + 1,
  ];
}

void main() {
  late Directory root;
  late String doc;
  late String readable;
  late String edited;

  setUp(() {
    final scratch = Directory('../../../ztmp')..createSync(recursive: true);
    root = scratch.createTempSync('tom_specs_clitool_spec_checks_render_');
    doc = '${root.path}/sbp.tomspecs.yaml';
    readable = '${root.path}/sbp.readable.md';
    edited = '${root.path}/sbp.edited.readable.md';
    File(_meridian).copySync(doc);
    // A citation in the order-capture value, so `-drop:all` strips a trace
    // span from it and the merge has a piece to put back.
    _replaceIn(doc, 'wholesale EDI adapter', 'wholesale EDI adapter $_cite');
  });
  tearDown(() => root.deleteSync(recursive: true));

  /// Exports the readable rendition with [switches] and copies it to the
  /// edited file, whose sentence [_edi] then reads `shall` for `must`.
  void exportAndEdit(List<String> switches) {
    final c = _Capture();
    expect(c.run(['render', doc, readable, ...switches]), 0, reason: c.err);
    File(readable).copySync(edited);
    _replaceIn(edited, _edi, _edi.replaceFirst('must', 'shall'));
  }

  group('RND-1 usage errors (exit 2)', () {
    int usage(List<String> args, String message) {
      final c = _Capture();
      final code = c.run(['render', ...args]);
      expect(c.err, contains(message), reason: args.join(' '));
      expect(c.err, contains('usage: tomspecs :spec-readable'));
      return code;
    }

    test('RND-1.1 no document, or too many paths', () {
      expect(usage([], 'usage:'), 2);
      expect(usage([doc, readable, edited], 'usage:'), 2);
    });

    test("RND-1.2 writing over the document or its own .tomspecs.md", () {
      expect(usage([doc, doc], 'overwrite the document itself'), 2);
      expect(
        usage([
          doc,
          '${root.path}/sbp.tomspecs.md',
        ], "document's own rendition"),
        2,
      );
      expect(File('${root.path}/sbp.tomspecs.md').existsSync(), isFalse);
    });

    test('RND-1.3 unknown names, comments unmarked, a name in two lists', () {
      expect(usage([doc, '-drop:nonsense'], 'nonsense'), 2);
      expect(usage([doc, '-unmark:comments'], 'comments'), 2);
      expect(usage([doc, '-drop:trace', '-unmark:trace'], 'trace'), 2);
      expect(usage([doc, '--appendix-references'], 'appendix'), 2);
      expect(usage([doc, '--nonsense'], 'unknown switch `--nonsense`'), 2);
    });

    test('RND-1.4 --base and --write belong to --merge-onto', () {
      expect(usage([doc, '--write'], '--write belongs to --merge-onto'), 2);
      expect(usage([doc, '--base', doc], '--base belongs to --merge-onto'), 2);
      expect(
        usage(['--merge-onto', doc, edited, readable], 'one edited rendition'),
        2,
      );
    });

    test('RND-1.5 merge switches disagreeing with the readable header', () {
      exportAndEdit(['-drop:comments']);
      expect(
        usage(['--merge-onto', doc, edited, '-drop:trace'], 'disagree'),
        2,
      );
    });

    test('RND-1.6 a merge of a rendition without header or switches', () {
      final md = '${root.path}/plain.md';
      expect(_Capture().run(['validate', doc, md]), anyOf(0, 1));
      expect(usage(['--merge-onto', doc, md], 'header'), 2);
    });
  });

  group('RND-2 the readable rendition', () {
    test('RND-2.1 to a file: the header, the report per kind', () {
      final c = _Capture();
      expect(
        c.run(['render', doc, readable, '-drop:all', '--heading-divs']),
        0,
      );
      final text = File(readable).readAsStringSync();
      final header = text.split('\n')[1];
      expect(header, startsWith('<!-- readable: drop='));
      expect(header, contains('comments'));
      expect(header, contains('headings=divs'));
      expect(header, contains('of=sbp.tomspecs.yaml@'));
      expect(header, isNot(contains('commit=')));
      expect(c.out, startsWith('$header\n'));
      expect(
        c.out,
        contains('stripped  trace: 1 dropped, 0 unmarked, 0 moved'),
      );
      expect(c.out, contains('readable  $readable — 1 value(s) changed'));
      expect(text, contains('wholesale EDI adapter and'));
      expect(text, isNot(contains(_cite)));
    });

    test('RND-2.2 without an output path the rendition goes to stdout', () {
      final c = _Capture();
      expect(c.run(['render', doc, '-drop:comments']), 0);
      expect(c.out, startsWith('<!-- docspec: '));
      expect(c.out.split('\n')[1], startsWith('<!-- readable: drop=comments'));
      expect(c.err, contains('readable  stdout — '));
    });

    test(
      'RND-2.3 the switches as tomspecs options give the same rendition',
      () {
        _Capture().run(['render', doc, readable, '-drop:comments,trace']);
        final other = '${root.path}/other.readable.md';
        _Capture().run([
          'render',
          doc,
          other,
          '--drop=comments',
          '--drop',
          'trace',
        ]);
        expect(
          File(other).readAsStringSync(),
          File(readable).readAsStringSync(),
        );
      },
    );
  });

  group('RND-3 the merge back', () {
    test('RND-3.1 the dry run reports the merge and writes nothing', () {
      exportAndEdit(['-drop:comments']);
      final before = File(doc).readAsStringSync();
      final c = _Capture();
      expect(c.run(['render', '--merge-onto', doc, edited]), 0, reason: c.err);
      expect(c.out, contains('MERGED SBP/'));
      expect(c.out, contains('merge     1 value(s), '));
      expect(c.out, contains('yaml      1 block scalar(s) rewritten in place'));
      expect(c.out, endsWith('dry run   nothing written\n'));
      expect(File(doc).readAsStringSync(), before);
      expect(File('${root.path}/sbp.tomspecs.md').existsSync(), isFalse);
    });

    test('RND-3.2 --write rewrites the one line and regenerates the .md', () {
      exportAndEdit(['-drop:all', '--heading-divs']);
      final before = File(doc).readAsStringSync();
      final c = _Capture();
      expect(
        c.run(['render', '--merge-onto', doc, edited, '--write']),
        0,
        reason: c.err,
      );
      expect(c.out, contains('— 1 pieces put back'));
      expect(c.out, contains('written   $doc'));
      expect(c.out, contains('rendition ${root.path}/sbp.tomspecs.md'));
      final after = File(doc).readAsStringSync();
      final lines = _changedLines(before, after);
      expect(lines, hasLength(1));
      expect(
        after,
        contains('${_edi.replaceFirst('must', 'shall')} $_cite and'),
      );
      expect(File('$doc.render.stage').existsSync(), isFalse);
      final md = File('${root.path}/sbp.tomspecs.md').readAsStringSync();
      expect(md, contains(_edi.replaceFirst('must', 'shall')));
      // The same rendition merged again onto the moved original: the
      // original's revision differs from the header's, there is no commit
      // to read the export from, so the stale merge is refused.
      final again = _Capture();
      expect(again.run(['render', '--merge-onto', doc, edited]), 1);
      expect(again.out, contains('nothing written'));
    });

    test('RND-3.3 a stale original merges three ways with --base', () {
      exportAndEdit(['-drop:comments']);
      final atExport = '${root.path}/sbp.at-export.tomspecs.yaml';
      File(doc).copySync(atExport);
      _replaceIn(doc, _pricing, 'Pricing is computed synchronously');
      final c = _Capture();
      expect(
        c.run([
          'render',
          '--merge-onto',
          doc,
          edited,
          '--base',
          atExport,
          '--write',
        ]),
        0,
        reason: c.err,
      );
      expect(c.out, contains('three-way'));
      final after = File(doc).readAsStringSync();
      expect(after, contains(_edi.replaceFirst('must', 'shall')));
      expect(after, contains('Pricing is computed synchronously'));
    });

    test('RND-3.4 a value changed on both sides is a conflict (exit 1)', () {
      exportAndEdit(['-drop:comments']);
      final atExport = '${root.path}/sbp.at-export.tomspecs.yaml';
      File(doc).copySync(atExport);
      _replaceIn(doc, _edi, _edi.replaceFirst('must', 'will'));
      final before = File(doc).readAsStringSync();
      final c = _Capture();
      expect(
        c.run([
          'render',
          '--merge-onto',
          doc,
          edited,
          '--base',
          atExport,
          '--write',
        ]),
        1,
      );
      expect(c.err, contains('CONFLICT'));
      expect(c.err, contains('changed in the original since the export'));
      expect(c.out, contains('nothing written'));
      expect(File(doc).readAsStringSync(), before);
    });

    test('RND-3.5 a section removed in the rendition is refused (exit 1)', () {
      exportAndEdit(['-drop:comments']);
      final text = File(edited).readAsStringSync();
      final lines = text.split('\n');
      final at = lines.lastIndexWhere((l) => l.startsWith('### <!--['));
      expect(at, greaterThan(0));
      final end = lines.indexWhere(
        (l) => RegExp(r'^#{1,3} ').hasMatch(l),
        at + 1,
      );
      lines.removeRange(at, end < 0 ? lines.length : end);
      File(edited).writeAsStringSync(lines.join('\n'));
      final before = File(doc).readAsStringSync();
      final c = _Capture();
      expect(c.run(['render', '--merge-onto', doc, edited, '--write']), 1);
      expect(c.err, contains('REFUSED'));
      expect(File(doc).readAsStringSync(), before);
    });
  });
}
