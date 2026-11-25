/// Where `TypstCompiler.find` looks: an explicit path, then the binaries
/// layer `$TOM_BINARY_PATH/<platform>/` (TomNativeBinaries; under `dart test`
/// there is no application bundle), then PATH.
@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_basics/native_binaries.dart';
import 'package:tom_md_export/src/typst_runner.dart';

void main() {
  late Directory layer;

  setUp(() => layer = Directory.systemTemp.createTempSync('md_export_typst_'));
  tearDown(() => layer.deleteSync(recursive: true));

  File fakeTypst(String folder) {
    final file = File(p.join(folder, 'typst'))
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\necho "typst 0.0.0 (fake)"\n');
    Process.runSync('chmod', ['+x', file.path]);
    return file;
  }

  test('MDX-TYPST-1: the binaries layer\'s platform folder is the one '
      'TomNativeBinaries names', () {
    expect(TypstCompiler.platformFolder(), TomNativeBinaries.platformFolder());
  });

  test(
    'MDX-TYPST-2: typst is found in \$TOM_BINARY_PATH/<platform>/',
    () async {
      final typst = fakeTypst(
        p.join(layer.path, TomNativeBinaries.platformFolder()),
      );
      final compiler = await TypstCompiler.find(
        environment: {'TOM_BINARY_PATH': layer.path},
      );
      expect(compiler.executable, typst.path);
    },
  );

  test('MDX-TYPST-3: an explicit path that does not run is refused', () {
    expect(
      TypstCompiler.find(explicit: p.join(layer.path, 'missing-typst')),
      throwsA(isA<TypstNotFound>()),
    );
  });
}
