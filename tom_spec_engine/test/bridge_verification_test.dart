/// The guard that stops `regenerate_bridges.dart` stamping a run that produced
/// nothing.
///
/// `GenerationResult.isSuccess` is `errors.isEmpty`, and the generator has a
/// path that resolves cleanly, emits nothing, reports no error and still names
/// its output file. Measured against the real generator with a barrel that
/// parses but exports nothing bridgeable:
///
///     totalClasses=0  outputFiles=2  errors=0  isSuccess=true
///     probe_bridges.b.dart exists=false
///
/// On that path the tool used to print `Success: true` and write
/// `som_surface.stamp.json` — certifying a bridge set that was never
/// regenerated, so the freshness test one step downstream would then pass over
/// stale bridges. These tests hold every way that run must instead fail.
library;

import 'dart:io';

import 'package:test/test.dart';

import '../tool/bridge_verification.dart';

void main() {
  late Directory dir;
  late DateTime startedAt;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bridge_verify_');
    // A generation always begins before it writes; the helpers below write
    // after this, so a written file is legitimately "fresh".
    startedAt = DateTime.now();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name, String content) =>
      File('${dir.path}/$name')..writeAsStringSync(content);

  /// A file whose modification time predates the run — the shape a previous
  /// run's output has when this run leaves it untouched.
  File stale(String name) {
    final f = write(name, '// last run\n');
    f.setLastModifiedSync(startedAt.subtract(const Duration(hours: 1)));
    return f;
  }

  String? verify({
    int totalClasses = 5,
    List<String> outputFiles = const [],
    List<String> errors = const [],
  }) => bridgeRegenerationFailure(
    totalClasses: totalClasses,
    outputFiles: outputFiles,
    errors: errors,
    startedAt: startedAt,
  );

  group('a sound run passes', () {
    test('classes generated and every named file freshly written', () {
      final a = write('a.b.dart', '// generated\n');
      final b = write('b.b.dart', '// generated\n');
      expect(verify(outputFiles: [a.path, b.path]), isNull);
    });

    test('a file stamped a whole second before the start still passes', () {
      // Modification times are truncated to whole seconds, so a file written a
      // millisecond after `startedAt` reads back as up to 999ms before it.
      // This pins the worst case of that truncation — and it is why the
      // tolerance is two seconds rather than one: at one second this
      // assertion's outcome depended on the sub-second part of `startedAt`,
      // which is exactly how the flake presented.
      final f = write('a.b.dart', '// generated\n');
      f.setLastModifiedSync(
        startedAt.subtract(const Duration(milliseconds: 999)),
      );
      expect(verify(outputFiles: [f.path]), isNull);
    });

    test('the tolerance is wider than the truncation quantum', () {
      expect(
        bridgeMtimeTolerance,
        greaterThan(const Duration(seconds: 1)),
        reason:
            'whole-second truncation can move a stamp by up to 999ms, so a '
            'one-second tolerance is consumed entirely by it',
      );
    });
  });

  group('a failed run is refused', () {
    test('the generator reporting errors', () {
      final f = write('a.b.dart', '// generated\n');
      final failure = verify(
        outputFiles: [f.path],
        errors: ['Undefined name TomBuildConfig', 'and another'],
      );
      expect(failure, isNotNull);
      expect(failure, contains('2 error(s)'));
      expect(
        failure,
        contains('Undefined name TomBuildConfig'),
        reason: 'the reason must carry the errors, not just their count',
      );
    });

    test('no output files named at all', () {
      expect(verify(outputFiles: const []), contains('no output files'));
    });

    test('zero classes generated with no error — the silent no-op', () {
      // The measured hole. Everything else looks healthy: files exist, are
      // non-empty, are fresh, and the generator is content.
      final f = write('a.b.dart', '// generated\n');
      final failure = verify(totalClasses: 0, outputFiles: [f.path]);
      expect(failure, isNotNull);
      expect(failure, contains('0 classes'));
      expect(
        failure,
        contains('buildkit.yaml'),
        reason: 'the message should say where to look, not just what is wrong',
      );
    });

    test('a named output file that was never written', () {
      final failure = verify(outputFiles: ['${dir.path}/absent.b.dart']);
      expect(failure, contains('never wrote it'));
    });

    test('a named output file written empty', () {
      final f = write('a.b.dart', '');
      expect(verify(outputFiles: [f.path]), contains('empty'));
    });

    test('a file left over from a previous run', () {
      // The check that actually closes the hole: in a real checkout the last
      // run's bridges are already on disk, so existence and non-emptiness are
      // both satisfied by exactly the file that must NOT be certified.
      final f = stale('a.b.dart');
      final failure = verify(outputFiles: [f.path]);
      expect(failure, isNotNull);
      expect(failure, contains('untouched'));
      expect(
        failure,
        contains('certify it as freshly generated'),
        reason: 'the message must name the consequence, which is the point',
      );
    });

    test('one stale file among fresh ones still fails', () {
      final fresh = write('a.b.dart', '// generated\n');
      final old = stale('b.b.dart');
      expect(verify(outputFiles: [fresh.path, old.path]), contains('b.b.dart'));
    });
  });

  group('the reasons are ordered so the cause is reported, not a symptom', () {
    test('generator errors outrank the missing file they caused', () {
      // A failed generation typically writes nothing, so both checks fire.
      // Reporting "never wrote it" would send a reader looking at the file
      // system instead of at the compiler output that explains it.
      final failure = verify(
        totalClasses: 0,
        outputFiles: ['${dir.path}/absent.b.dart'],
        errors: ['Undefined name TomBuildConfig'],
      );
      expect(failure, contains('TomBuildConfig'));
      expect(failure, isNot(contains('never wrote it')));
    });

    test('zero classes outranks the file checks', () {
      final f = stale('a.b.dart');
      final failure = verify(totalClasses: 0, outputFiles: [f.path]);
      expect(failure, contains('0 classes'));
      expect(failure, isNot(contains('untouched')));
    });
  });
}
