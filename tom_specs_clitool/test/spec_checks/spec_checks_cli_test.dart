// Tests of the `spec_checks` command (lib/src/spec_checks_cli.dart): the
// subcommands, usage errors, and where a check finds the project's data —
// `<spec-root>/checks/` beside the document, or `--spec-root`.
//
// The shipped Meridian Solution Blueprint (tom_som_dart_v0/documents/) is the
// document; each test copies it into a scratch spec root of its own under the
// workspace's ztmp/.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/spec_checks_cli.dart';

const _meridian =
    '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml';

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

void main() {
  late Directory root;
  late String doc;

  setUp(() {
    final scratch = Directory('../../../ztmp')..createSync(recursive: true);
    root = scratch.createTempSync('tom_specs_clitool_spec_checks_cli_');
    Directory('${root.path}/phase2').createSync();
    doc = '${root.path}/phase2/sbp.docspecs.yaml';
    File(_meridian).copySync(doc);
  });
  tearDown(() => root.deleteSync(recursive: true));

  group('CLI-1 usage', () {
    test('CLI-1.1 no arguments and an unknown check are usage errors', () {
      expect(_Capture().run([]), 2);
      final c = _Capture();
      expect(c.run(['nonsense']), 2);
      expect(c.err, contains('unknown check `nonsense`'));
    });

    test('CLI-1.2 a check with the wrong arguments prints its usage', () {
      final c = _Capture();
      expect(c.run(['feature-register']), 2);
      expect(c.err, contains('usage: spec_checks feature-register'));
    });

    test('CLI-1.3 --help lists every check', () {
      final c = _Capture();
      expect(c.run(['--help']), 0);
      for (final name in specChecksCommands.keys) {
        expect(c.out, contains('  $name '));
      }
    });
  });

  group('CLI-2 spec root', () {
    test('CLI-2.1 the nearest folder above the document holding checks/', () {
      Directory('${root.path}/checks').createSync();
      expect(specRootOf(doc), File(doc).absolute.parent.parent.path);
      Directory('${root.path}/phase2/checks').createSync();
      expect(specRootOf(doc), File(doc).absolute.parent.path);
    });

    test('CLI-2.2 without a checks/ folder: the document folder\'s parent', () {
      expect(specRootOf(doc), File(doc).absolute.parent.parent.path);
      expect(specRootOf(doc, '/x'), '/x');
    });

    test('CLI-2.3 a check whose data the project lacks says where it goes', () {
      final c = _Capture();
      expect(c.run(['authorization', doc]), 2);
      expect(c.err, contains('checks/authorization_cross_check.yaml'));
    });
  });

  group('CLI-3 checks on the Meridian Blueprint', () {
    test('CLI-3.1 validate writes the rendition and reports both tiers', () {
      final c = _Capture();
      final md = '${root.path}/phase2/sbp.md';
      final code = c.run(['validate', doc, md]);
      expect(c.out, startsWith('decode    OK\nrendition $md\n'));
      expect(c.out, contains('schema    '));
      expect(c.out, contains('instance  '));
      expect(File(md).existsSync(), isTrue);
      expect(code, c.err.isEmpty ? 0 : 1);
    });

    test(
      'CLI-3.2 import-answers of an unchanged rendition imports nothing',
      () {
        final md = '${root.path}/phase2/sbp.md';
        _Capture().run(['validate', doc, md]);
        final before = File(doc).readAsStringSync();
        final c = _Capture();
        c.run(['import-answers', '--dry-run', doc, md]);
        expect(c.out, contains('import    0 answer(s), 0 other value(s)'));
        expect(c.out, contains('dry run   nothing written'));
        expect(File(doc).readAsStringSync(), before);
      },
    );

    test(
      'CLI-3.3 required-fields and feature-register report their totals',
      () {
        final r = _Capture()..run(['required-fields', doc]);
        expect(
          r.out,
          matches(RegExp(r'forms checked \d+ missing \d+ bad types \d+')),
        );
        final f = _Capture()..run(['feature-register', doc]);
        expect(f.out, contains('functional requirements'));
      },
    );

    test('CLI-3.4 accept-marks without marks changes nothing', () {
      final before = File(doc).readAsStringSync();
      final c = _Capture();
      expect(c.run(['accept-marks', doc, '--write']), 0);
      expect(c.out, contains('value differences vs runtime: 0'));
      expect(File(doc).readAsStringSync(), before);
    });

    test('CLI-3.5 question-register reads checks/question_register.yaml', () {
      final index = '${root.path}/phase2/index.md';
      File(index).writeAsStringSync('# Questions\n');
      final defaults = _Capture()..run(['question-register', doc, index]);
      Directory('${root.path}/checks').createSync();
      File('${root.path}/checks/question_register.yaml').writeAsStringSync(
        'prefixes: [ZZ]\n'
        'groups:\n  - {key: z, label: "ZZ-01 to ZZ-{max}", prefix: ZZ}\n'
        'statuses:\n  - {key: open, label: open, waiting: true}\n',
      );
      final configured = _Capture()..run(['question-register', doc, index]);
      expect(defaults.out, contains('register  '));
      expect(configured.out, contains('register  '));
      // With prefix ZZ only, none of the document's question blocks counts.
      expect(configured.out, contains(' 0 blocks in the Blueprint'));
    });
  });
}
