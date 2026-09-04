/// Tests for the release-set dependency-closure check
/// (lib/src/release_closure.dart).
///
/// RCL1 is the live gate: it walks the real tree with the committed
/// tool/release_set.yaml in the default `dart test` run, so a dependency
/// added to any release package later goes red here rather than passing
/// unseen — the same discipline as the freshness stamps. RCL2–RCL6 hold the
/// walker's verdicts against synthetic fixtures.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/release_closure.dart';

void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final manifestPath = p.join(clitoolRoot, 'tool', 'release_set.yaml');

  group('RCL1: the live tree is closed', () {
    test('the committed manifest walks the real tree at zero violations', () {
      final manifest = ReleaseManifest.load(manifestPath);
      final report = checkReleaseClosure(
          manifest: manifest, containerRoot: containerRoot);
      expect(
        report.violations.map((v) => v.describe()),
        isEmpty,
        reason: 'the release set must stay dependency-closed — an edge onto '
            'the engine/brain/assistant/d4rt plane or an unapproved '
            'workspace package pulls excluded code into the release',
      );
      expect(report.packagesWalked, manifest.releaseSet.length,
          reason: 'every Dart member must actually be walked');
      expect(report.edgesChecked, greaterThan(0));
    });
  });

  group('RCL2–RCL6: fixture verdicts', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('release_closure_'));
    tearDown(() => root.deleteSync(recursive: true));

    void writePackage(String dir, String name, String deps,
        {String devDeps = '', String? overridesFile}) {
      final pkgDir = Directory(p.join(root.path, dir))
        ..createSync(recursive: true);
      File(p.join(pkgDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: $name
environment:
  sdk: ^3.0.0
dependencies:
$deps
dev_dependencies:
$devDeps
''');
      if (overridesFile != null) {
        File(p.join(pkgDir.path, 'pubspec_overrides.yaml'))
            .writeAsStringSync(overridesFile);
      }
    }

    ReleaseManifest manifest({
      Map<String, String> releaseSet = const {},
      Map<String, ReleaseAllowEntry> allow = const {},
      List<String> forbid = const [
        'tom_brain_*',
        'tom_assistant*',
        'tom_d4rt',
        'tom_spec_engine',
      ],
    }) =>
        ReleaseManifest(
          releaseSet: releaseSet,
          sourceOnly: const [],
          allow: allow,
          forbid: forbid,
          workspacePrefixes: const ['tom_'],
        );

    test('RCL2: a forbidden dependency fails naming the edge', () {
      writePackage('pkg_a', 'tom_pkg_a', '  tom_brain_shared: ^1.0.0\n');
      final report = checkReleaseClosure(
        manifest: manifest(releaseSet: {'tom_pkg_a': 'pkg_a'}),
        containerRoot: root.path,
      );
      expect(report.isClosed, isFalse);
      final v = report.violations.single;
      expect(v.kind, ClosureViolationKind.forbidden);
      expect(v.describe(), contains('tom_pkg_a -> tom_brain_shared'));
    });

    test('RCL2: a forbidden dev dependency fails too', () {
      writePackage('pkg_a', 'tom_pkg_a', '  path: ^1.9.0\n',
          devDeps: '  tom_assistant_core: ^1.0.0\n');
      final report = checkReleaseClosure(
        manifest: manifest(releaseSet: {'tom_pkg_a': 'pkg_a'}),
        containerRoot: root.path,
      );
      final v = report.violations.single;
      expect(v.kind, ClosureViolationKind.forbidden);
      expect(v.edgeKind, ClosureEdgeKind.devDependency);
      expect(v.describe(), contains('tom_pkg_a -> tom_assistant_core'));
    });

    test('RCL2: a forbidden pubspec_overrides entry fails too', () {
      writePackage('pkg_a', 'tom_pkg_a', '  path: ^1.9.0\n',
          overridesFile: 'dependency_overrides:\n'
              '  tom_d4rt:\n    path: ../elsewhere\n');
      final report = checkReleaseClosure(
        manifest: manifest(releaseSet: {'tom_pkg_a': 'pkg_a'}),
        containerRoot: root.path,
      );
      final v = report.violations.single;
      expect(v.kind, ClosureViolationKind.forbidden);
      expect(v.edgeKind, ClosureEdgeKind.override);
    });

    test('RCL3: an unapproved workspace dependency fails; third-party passes',
        () {
      writePackage(
          'pkg_a', 'tom_pkg_a', '  tom_mystery: ^1.0.0\n  args: ^2.6.0\n');
      final report = checkReleaseClosure(
        manifest: manifest(releaseSet: {'tom_pkg_a': 'pkg_a'}),
        containerRoot: root.path,
      );
      final v = report.violations.single;
      expect(v.kind, ClosureViolationKind.unapprovedWorkspace);
      expect(v.describe(), contains('tom_pkg_a -> tom_mystery'));
    });

    test('RCL4: the walk continues through an approved crossing and catches '
        'what sits behind it', () {
      writePackage('pkg_a', 'tom_pkg_a', '  tom_published: ^1.0.0\n');
      writePackage('published', 'tom_published', '  tom_brain_memory: ^1.0.0\n');
      final report = checkReleaseClosure(
        manifest: manifest(
          releaseSet: {'tom_pkg_a': 'pkg_a'},
          allow: {
            'tom_published': const ReleaseAllowEntry(
                name: 'tom_published',
                path: 'published',
                reason: 'published to pub.dev'),
          },
        ),
        containerRoot: root.path,
      );
      final v = report.violations.single;
      expect(v.kind, ClosureViolationKind.forbidden);
      expect(v.describe(), contains('tom_published -> tom_brain_memory'),
          reason: 'approving the crossing must not approve what sits behind '
              'it');
      expect(report.approvedCrossings, 1);
    });

    test('RCL4: a clean approved crossing passes', () {
      writePackage('pkg_a', 'tom_pkg_a', '  tom_published: ^1.0.0\n');
      writePackage('published', 'tom_published', '  yaml: ^3.1.2\n');
      final report = checkReleaseClosure(
        manifest: manifest(
          releaseSet: {'tom_pkg_a': 'pkg_a'},
          allow: {
            'tom_published': const ReleaseAllowEntry(
                name: 'tom_published',
                path: 'published',
                reason: 'published to pub.dev'),
          },
        ),
        containerRoot: root.path,
      );
      expect(report.violations, isEmpty);
    });

    test('RCL5: an allow entry matching a forbid pattern is a manifest error',
        () {
      writePackage('pkg_a', 'tom_pkg_a', '  {}\n');
      final report = checkReleaseClosure(
        manifest: manifest(
          releaseSet: {'tom_pkg_a': 'pkg_a'},
          allow: {
            'tom_brain_memory': const ReleaseAllowEntry(
                name: 'tom_brain_memory', reason: 'nice try'),
          },
        ),
        containerRoot: root.path,
      );
      expect(
        report.violations.map((v) => v.kind),
        contains(ClosureViolationKind.manifest),
      );
      expect(report.violations.map((v) => v.describe()).join('\n'),
          contains('tom_brain_memory'));
    });

    test('RCL6: a path dependency pointing at a stray copy fails', () {
      writePackage('pkg_a', 'tom_pkg_a',
          '  tom_pkg_b:\n    path: ../stray/pkg_b\n');
      writePackage('pkg_b', 'tom_pkg_b', '  {}\n');
      writePackage('stray/pkg_b', 'tom_pkg_b', '  {}\n');
      final report = checkReleaseClosure(
        manifest: manifest(
            releaseSet: {'tom_pkg_a': 'pkg_a', 'tom_pkg_b': 'pkg_b'}),
        containerRoot: root.path,
      );
      expect(
        report.violations.map((v) => v.kind),
        contains(ClosureViolationKind.pathMismatch),
      );
    });

    test('RCL6: a pubspec whose name disagrees with the manifest key fails',
        () {
      writePackage('pkg_a', 'tom_pkg_renamed', '  {}\n');
      final report = checkReleaseClosure(
        manifest: manifest(releaseSet: {'tom_pkg_a': 'pkg_a'}),
        containerRoot: root.path,
      );
      final v = report.violations.single;
      expect(v.kind, ClosureViolationKind.manifest);
      expect(v.describe(), contains('tom_pkg_renamed'));
    });

    test('RCL6: a missing source_only directory fails', () {
      writePackage('pkg_a', 'tom_pkg_a', '  {}\n');
      final report = checkReleaseClosure(
        manifest: ReleaseManifest(
          releaseSet: const {'tom_pkg_a': 'pkg_a'},
          sourceOnly: const ['gone_dir'],
          allow: const {},
          forbid: const [],
          workspacePrefixes: const ['tom_'],
        ),
        containerRoot: root.path,
      );
      final v = report.violations.single;
      expect(v.kind, ClosureViolationKind.manifest);
      expect(v.describe(), contains('gone_dir'));
    });
  });

  group('RCL7: manifest loading', () {
    test('an allow entry without a reason refuses to load', () {
      final dir = Directory.systemTemp.createTempSync('release_manifest_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'release_set.yaml'))
        ..writeAsStringSync('''
release_set:
  tom_pkg_a: pkg_a
allow:
  tom_published:
    path: published
''');
      expect(() => ReleaseManifest.load(file.path),
          throwsA(isA<FormatException>()));
    });

    test('the committed manifest loads and names every member once', () {
      final manifest = ReleaseManifest.load(manifestPath);
      expect(manifest.releaseSet, isNotEmpty);
      expect(manifest.sourceOnly, isNotEmpty);
      expect(manifest.forbid, isNotEmpty);
      // The check's reason to exist: the excluded plane is in the forbid list.
      expect(manifest.isForbidden('tom_spec_engine'), isTrue);
      expect(manifest.isForbidden('tom_specs_editor'), isTrue);
      expect(manifest.isForbidden('tom_specs_reviewer'), isTrue);
      expect(manifest.isForbidden('tom_brain_memory'), isTrue);
      expect(manifest.isForbidden('tom_assistant_core'), isTrue);
      expect(manifest.isForbidden('tom_d4rt'), isTrue);
      expect(manifest.isForbidden('tom_d4rt_generator'), isTrue);
    });
  });
}
