// createAnalysisDriver on a package that was never resolved
// (lib/src/analyzer_bootstrap.dart). On a fresh checkout the model package has
// no package config until `dart pub get` runs there; analysing it anyway
// resolved none of its imports, and the generators emitted facades with no
// document roots without a word (found on legiondary01, tom_specs frzhold4).
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('analyzer_boot_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('AB-1 a package with dependencies and no package config is refused', () {
    File(
      p.join(dir.path, 'pubspec.yaml'),
    ).writeAsStringSync('name: m\ndependencies:\n  tom_specs_core: ^0.4.0\n');
    expect(
      () => createAnalysisDriver(dir.path),
      throwsA(
        isA<UnresolvedPackageException>().having(
          (e) => e.toString(),
          'message',
          contains('run `dart pub get` there first'),
        ),
      ),
    );
  });

  test('AB-2 a package without dependencies needs no package config', () {
    File(
      p.join(dir.path, 'pubspec.yaml'),
    ).writeAsStringSync('name: m\nenvironment:\n  sdk: ^3.11.0\n');
    expect(createAnalysisDriver(dir.path), isNotNull);
  });
}
