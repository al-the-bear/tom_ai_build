import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// End-to-end test for the B1 analyzer-summary generator (`bin/summaries.dart`,
/// OE-1). The SDK-summary path is deterministic and fast (a couple of seconds);
/// the heavy package-bundle path (~40 MB, ~30 s) is exercised by the real build
/// (`build.dart --generate-summaries`) and the committed assets, not in CI.
void main() {
  group('summaries.dart generator (OE-1 / B1)', () {
    test('--sdk-only writes a non-trivial sdk_summary.sum', () async {
      final clitoolRoot = Directory.current.path;
      final outDir = Directory.systemTemp.createTempSync('specs_summaries');
      addTearDown(() {
        if (outDir.existsSync()) outDir.deleteSync(recursive: true);
      });

      final result = await Process.run(
        'dart',
        [
          'run',
          p.join('bin', 'summaries.dart'),
          '--sdk-only',
          '--out-dir',
          outDir.path,
        ],
        workingDirectory: clitoolRoot,
      );

      expect(result.exitCode, 0,
          reason: 'generator failed:\n${result.stdout}\n${result.stderr}');

      final sdkSum = File(p.join(outDir.path, 'sdk_summary.sum'));
      expect(sdkSum.existsSync(), isTrue,
          reason: 'sdk_summary.sum was not produced');
      // A real SDK summary is multiple megabytes; guard against an empty/stub
      // write without pinning an exact (SDK-version-dependent) size.
      expect(sdkSum.lengthSync(), greaterThan(500 * 1024));

      // --sdk-only must skip the heavy package bundle.
      expect(File(p.join(outDir.path, 'packages.sum')).existsSync(), isFalse);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
