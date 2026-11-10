import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The documentation-build gate in the default `dart test` run: every governed
/// package's `dart doc` build is silent and links nowhere its author did not
/// choose.
///
/// The first run found three packages that were not: two unresolved
/// references in `tom_specs_core` and `tom_specs_clitool`, and a `[file]` in
/// `tom_specs_clitool` that `dart doc` had bound, with no warning, to the
/// unrelated `file` package.
String _packageRoot() => p.normalize(Directory.current.path);
String _containerRoot() =>
    p.normalize(p.join(_packageRoot(), '..', '..', '..'));

void main() {
  final set = DartdocBuildSet.parse(
    File(p.join(_packageRoot(), dartdocBuildSetPath)).readAsStringSync(),
  );

  group('documentation-build gate', () {
    test('DOCBUILD-1: the set names packages that are on disk', () {
      expect(set.packages, isNotEmpty);
      for (final package in set.packages) {
        expect(
          File(p.join(_containerRoot(), package, 'pubspec.yaml')).existsSync(),
          isTrue,
          reason: '$package is not a package',
        );
      }
    });

    test('DOCBUILD-2: every governed package builds silent, its links where it '
        'chose', () async {
      final scratch = Directory.systemTemp.createTempSync('dartdoc_gate_');
      addTearDown(() => scratch.deleteSync(recursive: true));
      // Each build is single-threaded analysis: a few side by side.
      // A package never resolved here documents nothing it imports, so every
      // link into a dependency reads as unresolved. It is named and left out;
      // the others are still checked.
      final unresolved = [
        for (final package in set.packages)
          if (!isResolvedPackage(
            p.join(_containerRoot(), package),
            _containerRoot(),
          ))
            package,
      ];
      final resolved = [
        for (final package in set.packages)
          if (!unresolved.contains(package)) package,
      ];
      final reports = <DartdocBuildReport>[];
      for (var i = 0; i < resolved.length; i += 4) {
        reports.addAll(
          await Future.wait([
            for (final package in resolved.skip(i).take(4))
              buildDartdoc(
                packageDir: p.join(_containerRoot(), package),
                scratchDir: scratch.path,
              ),
          ]),
        );
      }
      for (final report in reports) {
        expect(
          report.failedSilently,
          isFalse,
          reason: '${report.package}: dart doc failed\n${report.log}',
        );
        // Pages with no doc prose would let the link scan pass having read
        // nothing.
        expect(
          report.proseBlocks,
          greaterThan(0),
          reason: '${report.package}: no doc prose was read',
        );
        expect(
          [...report.warnings, ...report.strayLinks],
          isEmpty,
          reason: report.package,
        );
        expect(report.faults, 0, reason: report.package);
      }
      if (unresolved.isNotEmpty) {
        markTestSkipped(
          'not resolved here, so not built: ${unresolved.join(', ')} '
          '(run `dart pub get` there)',
        );
      }
    }, timeout: const Timeout(Duration(minutes: 8)));
  });

  group('the link scan', () {
    test('DOCBUILD-3: a prose link into an unchosen package is reported; a '
        'signature link and an allowed prose link are not', () {
      final scratch = Directory.systemTemp.createTempSync('doclinks_');
      addTearDown(() => scratch.deleteSync(recursive: true));
      Directory(p.join(scratch.path, 'x')).createSync();
      File(p.join(scratch.path, 'x', 'PasswordHash.html')).writeAsStringSync(
        '<section class="multi-line-signature"><a href="https://pub.dev/'
        'documentation/pointycastle/3.9.1/api/SecureRandom-class.html">'
        'SecureRandom</a></section>'
        '<section class="desc markdown"><p>The <a class="deprecated" '
        'href="https://pub.dev/documentation/vector_math/2.4.1/hash/">hash'
        '</a> and the <a href="https://pub.dev/documentation/tom_basics/'
        '3.1.1/tom_basics/TomRuntime-class.html">TomRuntime</a>.</p>'
        '</section>',
      );
      final scan = strayDoclinks(scratch.path, {'tom_basics', 'x'});
      expect(scan.stray, ['x/PasswordHash.html: [hash] -> vector_math']);
      expect(scan.blocks, 1);
      expect(scan.links, 2);
    });

    test('DOCBUILD-4: a package may link into its direct dependencies and '
        'what they re-export', () {
      final allowed = allowedDoclinkPackages(_packageRoot());
      expect(allowed, containsAll(['tom_specs_clitool', 'path', 'analyzer']));
      expect(allowed, isNot(contains('file')));
    });
  });
}
