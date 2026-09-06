/// The gate over the gates (`tom_specs_documentation_standard.md` §8).
///
/// The three citation gates hold whatever their default scan sets name, and
/// those sets are closed and enumerated. That is a deliberate choice with one
/// failure mode: a package documented today and listed tomorrow is ungated in
/// between, and nothing reports it. This suite closes that window — a file that
/// cites the doc set and that no default scan set reaches fails here, on the
/// same run as the gates themselves.
///
/// It walks the **real tree**, like `release_closure_test.dart` and
/// `model_freshness_test.dart`, because a fixture would only ever prove the
/// walker works on a fixture.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The container root, resolved from this package's location.
String _containerRoot() =>
    p.normalize(p.join(Directory.current.path, '..', '..', '..'));

void main() {
  group('scan-set coverage — every citing file is gated', () {
    test('no TomSpecs package cites the doc set from outside a scan set', () {
      final gaps = findScanSetGaps(
        containerRoot: _containerRoot(),
        packageRoots: tomSpecsPackageRoots,
      );
      expect(
        gaps.map((g) => g.toString()).toList(),
        isEmpty,
        reason: 'These files cite the doc set but no gate reads them. Add each '
            'to defaultCitedReadmes / defaultCitedDocFolders / '
            'defaultCitedSourceRoots in tom_specs_clitool/lib/src/.',
      );
    });

    test('the walk is not vacuous — it reaches the packages it names', () {
      // A coverage check that inspected nothing would pass loudest of all, so
      // assert the enumerated roots actually exist on disk.
      final root = _containerRoot();
      final missing = [
        for (final pkg in tomSpecsPackageRoots)
          if (!Directory(p.join(root, pkg)).existsSync()) pkg,
      ];
      expect(missing, isEmpty,
          reason: 'tomSpecsPackageRoots names a directory that is not here; '
              'the coverage check silently skips it.');
      expect(tomSpecsPackageRoots.length, greaterThanOrEqualTo(29));
    });

    test('an ungated citing package is reported — README, doc/ and lib', () {
      // Anti-vacuity, and the only honest way to get it: every real package is
      // now inside a scan set, so the walker is shown a package that is not.
      // A live-tree assertion of "no gaps" passes just as loudly when the
      // walker looks at nothing.
      final tmp = Directory.systemTemp.createTempSync('scan_set_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final pkg = Directory(p.join(tmp.path, 'tom_ai', 'ai_build', 'tom_fake'))
        ..createSync(recursive: true);
      File(p.join(pkg.path, 'README.md'))
          .writeAsStringSync('See `som_multiplatform_spec_model.md` §12.');
      Directory(p.join(pkg.path, 'doc')).createSync();
      File(p.join(pkg.path, 'doc', 'guide.md'))
          .writeAsStringSync('Per `tom_specs_model_rules.md` §5.2.');
      Directory(p.join(pkg.path, 'lib')).createSync();
      File(p.join(pkg.path, 'lib', 'fake.dart'))
          .writeAsStringSync('/// Per `codespecs_mapping.md` §4.1.\nclass A {}');

      final gaps = findScanSetGaps(
        containerRoot: tmp.path,
        packageRoots: const ['tom_ai/ai_build/tom_fake'],
      );

      expect(gaps.map((g) => g.kind).toSet(),
          {'README', 'doc folder', 'source tree'},
          reason: 'all three set kinds must be checked, not just the first');
      expect(gaps.first.toString(), contains('no default'));
    });

    test('a package that cites nothing needs no scan set', () {
      // The membership rule is *citing*, not *kind*: listing a package with no
      // citations would only add files to scan.
      final tmp = Directory.systemTemp.createTempSync('scan_set_quiet_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final pkg = Directory(p.join(tmp.path, 'tom_ai', 'ai_build', 'tom_quiet'))
        ..createSync(recursive: true);
      File(p.join(pkg.path, 'README.md')).writeAsStringSync('No citations.');
      Directory(p.join(pkg.path, 'lib')).createSync();
      File(p.join(pkg.path, 'lib', 'quiet.dart'))
          .writeAsStringSync('/// Plain prose.\nclass A {}');

      expect(
        findScanSetGaps(
          containerRoot: tmp.path,
          packageRoots: const ['tom_ai/ai_build/tom_quiet'],
        ),
        isEmpty,
      );
    });
  });
}
