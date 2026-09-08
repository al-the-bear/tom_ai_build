/// The formatting gate, in the default `dart test` run.
///
/// Packages drift out of `dart format` conformance and stay there: Dart 3.7
/// changed the formatter's style, and seven of the first ten quest packages sat
/// non-conforming for months because nothing looked. `tom_forge/tom_specs_editor`
/// sat there longer still, at 58 of 68 files, because it was outside the
/// manifest rather than outside the rule. This suite is what stops that
/// recurring: it runs the real formatter over the real manifest, like
/// `release_closure_test.dart` and `scan_set_coverage_test.dart` beside it,
/// because a fixture would only prove the walker works on a fixture.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

String _packageRoot() => p.normalize(Directory.current.path);
String _containerRoot() =>
    p.normalize(p.join(_packageRoot(), '..', '..', '..'));

void main() {
  group('formatting — every governed package is `dart format` clean', () {
    final manifestPath = p.join(_packageRoot(), 'tool', 'format_set.yaml');

    test('the manifest names packages that are on disk', () {
      // A renamed or moved package would otherwise shrink the gate's subject
      // in silence, which is the failure the manifest exists to prevent.
      final set = FormatSet.load(manifestPath);
      final missing = <String>[];
      set.resolveFiles(_containerRoot(), missingPackages: missing);
      expect(
        missing,
        isEmpty,
        reason: 'tool/format_set.yaml names a package that is not here',
      );
      // Anti-vacuity: the walker reporting no unformatted file over an empty
      // or truncated manifest is not a pass. The floor is the count at the
      // time of writing, so it may rise and cannot silently fall.
      expect(set.packages.length, greaterThanOrEqualTo(16));
    });

    test('nothing the formatter governs is unformatted', () {
      final report = checkFormatting(
        containerRoot: _containerRoot(),
        set: FormatSet.load(manifestPath),
      );

      // "Not checked" is not "clean". A formatter that could not run says so,
      // and the suite skips with the reason rather than passing on nothing.
      if (report.unavailable != null) {
        markTestSkipped('formatter unavailable: ${report.unavailable}');
        return;
      }

      expect(
        report.unformatted,
        isEmpty,
        reason:
            'Run `dart format <path>` on these. A file left unformatted '
            'invites the next person who touches it to reformat it '
            'incidentally, which buries their real change in the diff.',
      );
    });

    test('the check reports an unformatted file rather than repairing it', () {
      // Anti-vacuity, and the property that matters most: every real package is
      // clean, so a live "no findings" assertion passes just as loudly when the
      // walker looks at nothing. Show it a file that is not.
      final tmp = Directory.systemTemp.createTempSync('format_gate_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final lib = Directory(p.join(tmp.path, 'pkg', 'lib'))
        ..createSync(recursive: true);
      final target = File(p.join(lib.path, 'ugly.dart'))
        ..writeAsStringSync('void   main( ) {print("x") ;}\n');
      final before = target.readAsStringSync();

      final report = checkFormatting(
        containerRoot: tmp.path,
        set: const FormatSet(packages: ['pkg'], directories: ['lib']),
      );

      if (report.unavailable != null) {
        markTestSkipped('formatter unavailable: ${report.unavailable}');
        return;
      }
      expect(report.unformatted, ['pkg/lib/ugly.dart']);
      expect(report.isClean, isFalse);
      expect(
        target.readAsStringSync(),
        before,
        reason:
            'the gate reports; `dart format` repairs. A gate that '
            'rewrote files would edit a branch at a moment nobody chose',
      );
    });

    test('a missing manifest package is a finding, not a quiet skip', () {
      final tmp = Directory.systemTemp.createTempSync('format_gate_missing_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final report = checkFormatting(
        containerRoot: tmp.path,
        set: const FormatSet(packages: ['gone'], directories: ['lib']),
      );

      expect(report.missingPackages, ['gone']);
      expect(report.isClean, isFalse);
      // Nothing on disk to format, so the run never happened — and the report
      // says that rather than reporting an empty, clean-looking result.
      expect(report.unavailable, isNotNull);
    });
  });
}
