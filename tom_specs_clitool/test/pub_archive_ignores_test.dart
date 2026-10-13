/// Tests for the archive-ignore check (lib/src/pub_archive_ignores.dart).
///
/// PAI1 is the live gate: every Dart member of the committed release set is
/// dry-run published, and no file git tracks may be dropped from its archive
/// by a `.gitignore`. That is how the hand-written `doc/api/api_summary_*.md`
/// went missing from five archives — a repository-root ignore rule git and pub
/// read differently — so the gate asks pub itself rather than re-deriving its
/// rules. PAI2 holds the output parser to pub's wording.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/pub_archive_ignores.dart';
import 'package:tom_specs_clitool/src/release_closure.dart';

void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final manifest = ReleaseManifest.load(
    p.join(clitoolRoot, 'tool', 'release_set.yaml'),
  );

  group('PAI1: no release archive drops a checked-in file', () {
    for (final entry in manifest.releaseSet.entries) {
      test(entry.key, () async {
        final outcome = await checkPubArchiveIgnores(
          p.join(containerRoot, entry.value),
          packageName: entry.key,
        );
        expect(
          outcome.ran,
          isTrue,
          reason: 'the dry run never assembled the archive:\n${outcome.output}',
        );
        expect(
          outcome.ignoredFiles,
          isEmpty,
          reason:
              'these files are tracked but a .gitignore keeps them out of the '
              'archive; a file meant to stay out belongs in .pubignore',
        );
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });

  group('PAI2: parsing pub output', () {
    test('reads the listed paths and stops at the next item', () {
      const output = '''
Validating package...
Package has 1 warning.
* 2 checked-in files are ignored by a `.gitignore`.
  Files that are checked in while gitignored:
  doc/api/api_summary_a.md
  doc/api/api_summary_b.md

* Another warning.
''';
      expect(parseCheckedInIgnored(output), [
        'doc/api/api_summary_a.md',
        'doc/api/api_summary_b.md',
      ]);
    });

    test('reads the singular form', () {
      const output = '''
* 1 checked-in file is ignored by a `.gitignore`.
  Files that are checked in while gitignored:
  doc/api/api_summary_a.md
''';
      expect(parseCheckedInIgnored(output), ['doc/api/api_summary_a.md']);
    });

    test('a clean run names nothing', () {
      expect(parseCheckedInIgnored('Package has 0 warnings.\n'), isEmpty);
    });
  });
}
