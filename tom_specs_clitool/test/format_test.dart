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

/// Gives [dir] the package config `dart pub get` would write.
void _resolve(String dir) {
  File(p.join(dir, '.dart_tool', 'package_config.json'))
    ..createSync(recursive: true)
    ..writeAsStringSync('{"configVersion": 2, "packages": []}\n');
}

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
      _resolve(p.join(tmp.path, 'pkg'));
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

    test('an unresolved package is named, its files not judged', () {
      // Without a package config `dart format` formats at the newest language
      // version, not the package's, so a fresh checkout (bigbeast) reported
      // files as unformatted that were not. The gate says what is missing.
      final tmp = Directory.systemTemp.createTempSync('format_gate_unres_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final lib = Directory(p.join(tmp.path, 'pkg', 'lib'))
        ..createSync(recursive: true);
      File(
        p.join(lib.path, 'ugly.dart'),
      ).writeAsStringSync('void   main( ) {print("x") ;}\n');

      final report = checkFormatting(
        containerRoot: tmp.path,
        set: const FormatSet(packages: ['pkg'], directories: ['lib']),
      );

      expect(report.unresolvedPackages, ['pkg']);
      expect(report.unformatted, isEmpty);
      expect(report.isClean, isFalse);
      expect(report.summary, contains('not resolved'));
    });

    test('a package resolved by a workspace above it counts as resolved', () {
      final tmp = Directory.systemTemp.createTempSync('format_gate_ws_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      Directory(p.join(tmp.path, 'pkg', 'lib')).createSync(recursive: true);
      _resolve(tmp.path);
      final unresolved = <String>[];
      const FormatSet(
        packages: ['pkg'],
        directories: ['lib'],
      ).resolveFiles(tmp.path, unresolvedPackages: unresolved);
      expect(unresolved, isEmpty);
    });

    test('the files are batched under the command-line limit', () {
      // Windows caps a command line at 32,767 characters; one call over the
      // whole manifest failed there ("Dateiname oder Erweiterung zu lang").
      final files = [for (var i = 0; i < 1000; i++) '/ws/pkg/lib/f$i.dart'];
      final batches = formatBatches(files, maxChars: 1000);
      expect(batches.expand((b) => b), files);
      for (final b in batches) {
        expect(b.join(' ').length, lessThanOrEqualTo(1000));
        expect(b, isNotEmpty);
      }
      expect(formatBatches(['x' * 5000], maxChars: 1000), [
        ['x' * 5000],
      ]);
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
