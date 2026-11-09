import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The API-signature gate in the default `dart test` run: every signature a
/// gated package's API summary quotes agrees with the code.
///
/// The summaries are what a reader consults instead of the source; a stale
/// signature there misleads more directly than anywhere else, and every one
/// of them parses. The first run over this repository found 34 such faults in
/// four packages — constructors missing their newer parameters, quotes that
/// carried initializer lists and private constructors, types the package did
/// not export.
String _packageRoot() => p.normalize(Directory.current.path);
String _containerRoot() =>
    p.normalize(p.join(_packageRoot(), '..', '..', '..'));

void main() {
  final set = ApiSignatureSet.parse(
    File(p.join(_packageRoot(), apiSignatureSetPath)).readAsStringSync(),
  );

  group('API-signature gate', () {
    test('APISIG-1: the set names packages with summaries on disk', () {
      expect(set.entries, isNotEmpty);
      for (final e in set.entries) {
        expect(
          Directory(p.join(_containerRoot(), e.package, e.docs)).existsSync(),
          isTrue,
          reason: '${e.package}/${e.docs} is not there',
        );
      }
    });

    for (final e in set.entries) {
      test('APISIG-2: ${p.basename(e.package)} quotes the code', () async {
        final dir = p.join(_containerRoot(), e.package);
        final report = await checkApiSignatures(
          packageDir: dir,
          docDir: p.join(dir, e.docs),
        );
        expect(report.faults, isEmpty);
        // A package whose fences all read as samples would pass having
        // compared nothing.
        expect(
          report.members,
          greaterThan(0),
          reason: '${e.package} compared no quoted member',
        );
      }, timeout: const Timeout(Duration(minutes: 3)));
    }
  });

  group('the checker reports each kind of damage', () {
    late Directory scratch;
    setUp(() => scratch = Directory.systemTemp.createTempSync('apisig_'));
    tearDown(() => scratch.deleteSync(recursive: true));

    Future<List<String>> mutated(
      String package,
      String summary,
      String from,
      String to,
    ) async {
      final dir = p.join(_containerRoot(), 'tom_ai', 'ai_build', package);
      final text = File(p.join(dir, 'doc', 'api', summary)).readAsStringSync();
      expect(text, contains(from), reason: 'the anchor is gone; pick another');
      File(
        p.join(scratch.path, summary),
      ).writeAsStringSync(text.replaceFirst(from, to));
      final report = await checkApiSignatures(
        packageDir: dir,
        docDir: scratch.path,
      );
      return report.faults;
    }

    test('APISIG-3: a parameter quoted with the wrong type', () async {
      final faults = await mutated(
        'tom_specs_core',
        'api_summary_annotations.md',
        '  String name,\n',
        '  int name,\n',
      );
      expect(faults, [contains('is `String`, quoted as `int`')]);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('APISIG-4: a named parameter the code does not have, and the one it '
        'replaced', () async {
      final faults = await mutated(
        'tom_code_specs',
        'api_summary_annotations.md',
        'const CsElement({required this.kind, this.note});',
        'const CsElement({required this.kind, this.notes});',
      );
      expect(
        faults,
        unorderedEquals([
          contains('omits `note`'),
          contains('has no named parameter `notes`'),
        ]),
      );
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('APISIG-5: a const constructor quoted without const', () async {
      final faults = await mutated(
        'tom_code_specs',
        'api_summary_annotations.md',
        'const CsWidget({this.note});',
        'CsWidget({this.note});',
      );
      expect(faults, [contains('is const, quoted without it')]);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test(
      'APISIG-6: a fence cut off before its closing `})` does not parse',
      () async {
        final faults = await mutated(
          'tom_code_specs',
          'api_summary_annotations.md',
          'const CsWidget({this.note});',
          'const CsWidget({this.note,',
        );
        expect(faults, [contains('does not parse as a signature')]);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test('APISIG-7: a type the package does not make public', () async {
      final faults = await mutated(
        'tom_code_specs',
        'api_summary_annotations.md',
        'const CsWidget({this.note});',
        'const CsNotAType({this.note});',
      );
      expect(faults, [contains('`CsNotAType` is not a type')]);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
