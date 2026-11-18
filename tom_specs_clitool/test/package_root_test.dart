/// `clitoolPackageRoot` (lib/src/package_root.dart): from the package config
/// under `dart test`, and from the current directory where a compiled binary
/// has no package config (`clitoolRootAbove`).
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

void main() {
  final here = p.normalize(Directory.current.path);

  test('PR1: under dart test, the package config gives this package', () {
    expect(clitoolPackageRoot(), here);
  });

  test(
    'PR2: from the package, a folder in it, its sibling and the container',
    () {
      expect(clitoolRootAbove(here), here);
      expect(clitoolRootAbove(p.join(here, 'lib', 'src')), here);
      expect(clitoolRootAbove(p.join(here, '..', 'tom_specs_model')), here);
      expect(clitoolRootAbove(p.join(here, '..', '..', '..')), here);
    },
  );

  test('PR3: a folder outside any workspace has none', () {
    final tmp = Directory.systemTemp.createTempSync('package_root_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    expect(clitoolRootAbove(tmp.path), isNull);
  });
}
