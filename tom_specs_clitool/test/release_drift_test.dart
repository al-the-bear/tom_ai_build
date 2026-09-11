/// Tests for the release-drift gate (lib/src/release_drift.dart).
///
/// RDR1 is the live gate: it computes drift over the real tree with the
/// committed `tool/release_set.yaml`, in the default `dart test` run, so a
/// release package edited and not republished goes red here rather than being
/// discovered by a hand diff months later — which is exactly how the 34,604-line
/// `tom_specs_clitool` drift was found.
///
/// RDR2–RDR4 hold the parts a live run cannot exercise on demand: the
/// acknowledgement lookup, the ignore list, and the stale-acknowledgement
/// verdict.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/release_drift.dart';

void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final manifestPath = p.join(clitoolRoot, 'tool', 'release_set.yaml');

  group('RDR1: the live tree is published', () {
    test('every release member is at its published tree, or says why not', () {
      final report = computeReleaseDrift(
        containerRoot: containerRoot,
        manifestPath: manifestPath,
      );

      expect(
        report.packages,
        isNotEmpty,
        reason: 'a report over no packages is a broken walk, not a clean one',
      );

      final failed = report.violations
          .map(
            (v) =>
                '${v.package} (${v.version}): '
                '${v.versionCommit == null ? "no commit set this version" : "${v.changedFiles.length} file(s) changed"}',
          )
          .toList();

      expect(
        failed,
        isEmpty,
        reason:
            'a release member has moved since the commit that set its '
            'version, so pub.dev under-reports what this repository holds. '
            'Either publish it at a new version, or record why it is behind '
            'under `unpublished_drift:` in tool/release_set.yaml.\n'
            '${renderReleaseDrift(report).join('\n')}',
      );

      expect(
        report.unknownAcknowledgements,
        isEmpty,
        reason: 'an acknowledgement naming a non-member is itself stale',
      );
    });
  });

  group('RDR2: the acknowledgement block', () {
    test('an absent block reads as an empty one', () {
      final dir = Directory.systemTemp.createTempSync('drift_ack');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File(p.join(dir.path, 'm.yaml'))
        ..writeAsStringSync('release_set: {}\n');
      expect(loadAcknowledgedDrift(f.path), isEmpty);
    });

    test('reasons are read and trimmed', () {
      final dir = Directory.systemTemp.createTempSync('drift_ack2');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File(p.join(dir.path, 'm.yaml'))
        ..writeAsStringSync(
          'release_set: {}\n'
          'unpublished_drift:\n'
          '  tom_thing: >-\n'
          '    behind on purpose\n',
        );
      expect(loadAcknowledgedDrift(f.path), {'tom_thing': 'behind on purpose'});
    });
  });

  group('RDR3: what is not counted as drift', () {
    test('the ignore list names only non-shipped paths', () {
      // Pinned because a path added here silently shrinks what the gate sees.
      expect(releaseDriftIgnoredPaths, [
        'pubspec.lock',
        'tom_build_state.json',
        'testlog/',
        '.dart_tool/',
      ]);
    });
  });

  group('RDR5: a path .pubignore names is not published, so not drift', () {
    test('directory entries cover everything beneath them', () {
      expect(isPubIgnored('tool/validate_samples.dart', ['tool/']), isTrue);
      expect(isPubIgnored('tools/x.dart', ['tool/']), isFalse);
    });

    test('file entries match exactly, and as a directory prefix', () {
      const entries = ['test/conformance_test.dart', 'doc/api'];
      expect(isPubIgnored('test/conformance_test.dart', entries), isTrue);
      expect(isPubIgnored('test/other_test.dart', entries), isFalse);
      expect(isPubIgnored('doc/api/index.html', entries), isTrue);
    });

    test('a glob is read literally, so it fails safe', () {
      // Unsupported syntax must leave a file COUNTED as drift rather than
      // silently excuse it: an over-excusing gate hides exactly what it exists
      // to report.
      expect(isPubIgnored('lib/a.g.dart', ['*.g.dart']), isFalse);
    });

    test('comments and blank lines are not entries', () {
      final dir = Directory.systemTemp.createTempSync('pubignore');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(
        p.join(dir.path, '.pubignore'),
      ).writeAsStringSync('# why\n\ntool/\n  test/x.dart  \n');
      expect(readPubIgnore(dir.path), ['tool/', 'test/x.dart']);
    });

    test('no .pubignore means nothing is excused', () {
      final dir = Directory.systemTemp.createTempSync('pubignore_none');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(readPubIgnore(dir.path), isEmpty);
    });
  });

  group('RDR4: the verdict', () {
    test('drift is a violation only when it is not acknowledged', () {
      const drifted = PackageDrift(
        package: 'a',
        directory: 'x/a',
        version: '1.0.0',
        versionCommit: 'abc',
        changedFiles: ['x/a/lib/a.dart'],
        acknowledgedReason: null,
      );
      const excused = PackageDrift(
        package: 'b',
        directory: 'x/b',
        version: '1.0.0',
        versionCommit: 'abc',
        changedFiles: ['x/b/lib/b.dart'],
        acknowledgedReason: 'published on demand',
      );
      const clean = PackageDrift(
        package: 'c',
        directory: 'x/c',
        version: '1.0.0',
        versionCommit: 'abc',
        changedFiles: [],
        acknowledgedReason: null,
      );
      expect(drifted.isViolation, isTrue);
      expect(excused.isViolation, isFalse);
      expect(clean.isViolation, isFalse);
    });

    test('a version no commit ever set is a violation, not a clean pass', () {
      // The failure mode this closes: an unreadable or uncommitted version
      // yields no anchor, so a "no files changed" answer would be an artefact
      // of finding nothing to compare rather than a statement about the tree.
      const orphan = PackageDrift(
        package: 'a',
        directory: 'x/a',
        version: '9.9.9',
        versionCommit: null,
        changedFiles: [],
        acknowledgedReason: null,
      );
      expect(orphan.isViolation, isTrue);
    });
  });
}
