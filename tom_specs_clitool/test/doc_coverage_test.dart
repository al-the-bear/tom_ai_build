import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// The public-API dartdoc coverage gate in the default test run
/// (`tom_specs_documentation_standard.md` §5).
///
/// The point of running it here rather than only from the CLI is the same as
/// for the release-closure walk and the two freshness stamps beside it: a
/// standard nobody runs is a photograph. `tom_specs_clitool` reached 51 %
/// coverage by nobody noticing, and this is what makes that impossible to
/// repeat quietly.
void main() {
  final clitoolRoot = _clitoolRoot();
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final manifestFile = File(p.join(clitoolRoot, docCoverageManifestPath));

  late DocCoverageManifest manifest;

  setUpAll(() {
    manifest = DocCoverageManifest.parse(manifestFile.readAsStringSync());
  });

  group('doc-coverage gate', () {
    test(
      'every measured package is at or above its floor',
      () async {
        final report = await checkDocCoverage(
          manifest: manifest,
          containerRoot: containerRoot,
        );
        expect(
          report.violations.map((v) => v.toString()),
          isEmpty,
          reason:
              'raise the missing documentation, or — if a package was '
              'deliberately narrowed — lower nothing and say so in the '
              'manifest header',
        );
        expect(
          report.results,
          isNotEmpty,
          reason: 'a walk that measured nothing is not a passing gate',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test('the manifest carries the §5 target beside every floor', () {
      for (final e in manifest.entries) {
        expect(e.target, greaterThan(0), reason: '${e.path} has no §5 target');
        expect(e.floor, greaterThanOrEqualTo(0));
      }
    });

    test('every §5 bar is one of the two the standard states', () {
      // §5: 95% for libraries, tools and SOM runtimes; 90% for the reviewer.
      // A third number would mean the manifest had invented a bar rather than
      // transcribing one.
      for (final e in manifest.entries) {
        expect(
          e.target,
          anyOf(95, 90),
          reason: '${e.path} carries a target the standard does not state',
        );
      }
    });
  });

  group('membership', () {
    test(
      'an exempt package may not carry a threshold',
      () async {
        final poisoned = DocCoverageManifest(
          entries: [
            ...manifest.entries,
            DocCoverageEntry(path: manifest.exempt.first, floor: 0, target: 95),
          ],
          exempt: manifest.exempt,
          excluded: manifest.excluded,
        );
        final report = await checkDocCoverage(
          manifest: poisoned,
          containerRoot: containerRoot,
        );
        expect(
          report.violations.map((v) => v.package),
          contains(manifest.exempt.first),
          reason:
              'a generated package with a threshold blames the wrong '
              'artifact for an emitter bug',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'an excluded package may not carry a threshold',
      () async {
        final poisoned = DocCoverageManifest(
          entries: [
            ...manifest.entries,
            DocCoverageEntry(
              path: manifest.excluded.first,
              floor: 0,
              target: 95,
            ),
          ],
          exempt: manifest.exempt,
          excluded: manifest.excluded,
        );
        final report = await checkDocCoverage(
          manifest: poisoned,
          containerRoot: containerRoot,
        );
        expect(
          report.violations.map((v) => v.package),
          contains(manifest.excluded.first),
          reason:
              'an excluded package present at 0% reads as a standing debt, '
              'which is exactly what §6 decided it is not',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test('the nine generated facades are all exempt', () {
      expect(
        manifest.exempt.length,
        9,
        reason:
            'one per SOM language; a missing one could acquire a '
            'threshold unnoticed',
      );
      for (final e in manifest.exempt) {
        expect(e, contains('tom_som_'));
        expect(e, endsWith('_v0'));
      }
    });

    test('the editor is excluded, not measured', () {
      expect(manifest.excluded, contains('tom_forge/tom_specs_editor'));
      expect(
        manifest.entries.map((e) => e.path),
        isNot(contains('tom_forge/tom_specs_editor')),
      );
    });
  });

  group('the gate detects what it claims to', () {
    test('an undocumented public member is found', () async {
      final dir = await Directory.systemTemp.createTemp('doccov_');
      try {
        Directory(p.join(dir.path, 'lib')).createSync();
        File(p.join(dir.path, 'analysis_options.yaml')).writeAsStringSync(
          'linter:\n  rules:\n    public_member_api_docs: true\n',
        );
        File(p.join(dir.path, 'lib', 'a.dart')).writeAsStringSync('''
/// Documented.
class Documented {
  /// A documented field.
  int documented = 0;

  int undocumented = 0;
}
''');
        final r = await measurePackage(
          packagePath: dir.path,
          relativePath: 'probe',
        );
        expect(r.total, 3);
        expect(r.documented, 2);
        expect(r.undocumented.single, endsWith('Documented.undocumented'));
        expect(r.percent, lessThan(100));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('percent never rounds up to a false 100', () async {
      final dir = await Directory.systemTemp.createTemp('doccov_');
      try {
        Directory(p.join(dir.path, 'lib')).createSync();
        final b = StringBuffer('/// Documented.\nclass C {\n');
        for (var i = 0; i < 500; i++) {
          b.writeln('  /// Field $i.\n  int f$i = 0;');
        }
        b.writeln('  int missing = 0;\n}');
        File(p.join(dir.path, 'lib', 'a.dart')).writeAsStringSync('$b');
        final r = await measurePackage(
          packagePath: dir.path,
          relativePath: 'probe',
        );
        expect(r.documented, r.total - 1);
        expect(
          r.percent,
          99,
          reason:
              '501/502 is 99.8%, and a gate that reports it as 100 '
              'would let the last undocumented member through',
        );
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('a missing lint is a violation even at full coverage', () async {
      final dir = await Directory.systemTemp.createTemp('doccov_');
      try {
        Directory(p.join(dir.path, 'lib')).createSync();
        File(
          p.join(dir.path, 'lib', 'a.dart'),
        ).writeAsStringSync('/// Documented.\nclass C {}\n');
        final r = await measurePackage(
          packagePath: dir.path,
          relativePath: 'probe',
        );
        expect(r.percent, 100);
        expect(
          r.lintEnabled,
          isFalse,
          reason:
              'the gate runs once per test run; the lint is what holds '
              'the bar at edit time, so a measured package needs both',
        );
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test(
      'an @override member is not counted — it inherits its comment',
      () async {
        final dir = await Directory.systemTemp.createTemp('doccov_');
        try {
          Directory(p.join(dir.path, 'lib')).createSync();
          File(p.join(dir.path, 'lib', 'a.dart')).writeAsStringSync('''
/// Documented.
class C {
  @override
  String toString() => 'C';
}
''');
          final r = await measurePackage(
            packagePath: dir.path,
            relativePath: 'probe',
          );
          expect(r.total, 1, reason: 'the class only');
          expect(r.percent, 100);
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
    );

    test('a setter with a documented getter is not counted twice', () async {
      final dir = await Directory.systemTemp.createTemp('doccov_');
      try {
        Directory(p.join(dir.path, 'lib')).createSync();
        File(p.join(dir.path, 'lib', 'a.dart')).writeAsStringSync('''
/// Documented.
class C {
  int _v = 0;

  /// The pair's getter carries the comment.
  int get paired => _v;
  set paired(int value) => _v = value;
}
''');
        final r = await measurePackage(
          packagePath: dir.path,
          relativePath: 'probe',
        );
        expect(
          r.total,
          2,
          reason: 'the class and the property, not the setter',
        );
        expect(r.percent, 100);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}

/// The `tom_specs_clitool` root, found from the test's working directory.
String _clitoolRoot() {
  var dir = Directory.current.path;
  while (dir != p.dirname(dir)) {
    if (File(p.join(dir, 'pubspec.yaml')).existsSync() &&
        File(
          p.join(dir, 'pubspec.yaml'),
        ).readAsStringSync().contains('name: tom_specs_clitool')) {
      return dir;
    }
    dir = p.dirname(dir);
  }
  return Directory.current.path;
}
