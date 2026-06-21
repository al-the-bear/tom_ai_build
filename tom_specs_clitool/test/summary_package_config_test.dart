import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart'
    show readPackageRoots, mergePackageRootsForDirs, SummaryConfigException;

/// Tests for the B1 summary package-config helper (OE-1 / OE-25).
///
/// These exercise the *pure* config-reading/merging logic that feeds
/// `bin/summaries.dart`'s package-bundle build. They rely only on the resolved
/// `.dart_tool/package_config.json` files of two sibling packages that are
/// already `pub get`-resolved in the workspace — never on the heavy analyzer
/// bundle — so they stay fast and CI-safe.
void main() {
  // Tests run with cwd == project root (tom_specs_clitool).
  final clitoolDir = Directory.current.path;
  final codeSpecsDir = p.normalize(p.join(clitoolDir, '..', 'tom_code_specs'));

  final clitoolConfig =
      File(p.join(clitoolDir, '.dart_tool', 'package_config.json'));
  final codeSpecsConfig =
      File(p.join(codeSpecsDir, '.dart_tool', 'package_config.json'));

  group('readPackageRoots', () {
    test('returns name→root map for a resolved package_config.json', () {
      if (!clitoolConfig.existsSync()) {
        markTestSkipped('clitool package_config.json missing — run pub get');
        return;
      }
      final roots = readPackageRoots(clitoolConfig);
      expect(roots, contains('tom_specs_clitool'));
      // The recorded root is the package directory that contains `lib/`.
      final root = roots['tom_specs_clitool']!;
      expect(Directory(p.join(root, 'lib')).existsSync(), isTrue,
          reason: 'root should be the package dir containing lib/');
    });
  });

  group('mergePackageRootsForDirs', () {
    test('unions the dependency closures of multiple package dirs', () {
      if (!clitoolConfig.existsSync() || !codeSpecsConfig.existsSync()) {
        markTestSkipped('a sibling package_config.json is missing — run pub get');
        return;
      }
      final merged = mergePackageRootsForDirs([clitoolDir, codeSpecsDir]);
      // Packages unique to each config must both survive the union.
      expect(merged, contains('tom_specs_clitool')); // clitool closure
      expect(merged, contains('tom_code_specs')); // code_specs closure
    });

    test('throws SummaryConfigException for a dir without a resolved config',
        () {
      final tmp = Directory.systemTemp.createTempSync('oe25_no_config');
      addTearDown(() => tmp.deleteSync(recursive: true));
      expect(
        () => mergePackageRootsForDirs([tmp.path]),
        throwsA(isA<SummaryConfigException>()),
      );
    });
  });
}
