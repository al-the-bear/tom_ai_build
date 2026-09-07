/// Tests for the spec-tree doc-duplication ratchet
/// (lib/src/spec_tree_duplication.dart).
///
/// STD1 is the live gate: it measures the real reviewer and editor trees
/// against the committed baseline in the default `dart test` run, so a new
/// forked explanation goes red here rather than only when someone remembers
/// to run the binary — the same discipline as RCL1 and the freshness stamps.
/// STD2 holds the primitives against fixtures.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/spec_tree_duplication.dart';

void main() {
  final clitoolRoot = Directory.current.path;
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));

  group('STD1: the live trees are at or below baseline', () {
    test('no doc line is newly stated in both spec trees', () {
      final reviewer = Directory(p.join(containerRoot, reviewerTreeRoot));
      final editor = Directory(p.join(containerRoot, editorTreeRoot));

      // Anti-vacuity. The two trees live in different repos, and a checkout
      // missing one of them would make the intersection empty and this test
      // pass having compared nothing — the one outcome a gate must not have.
      expect(
        reviewer.existsSync(),
        isTrue,
        reason: 'reviewer tree not found at ${reviewer.path}',
      );
      expect(
        editor.existsSync(),
        isTrue,
        reason: 'editor tree not found at ${editor.path}',
      );
      expect(docCommentLines(reviewer), isNotEmpty);
      expect(docCommentLines(editor), isNotEmpty);

      final baselineFile = File(p.join(clitoolRoot, sharedDocBaselinePath));
      expect(
        baselineFile.existsSync(),
        isTrue,
        reason:
            'no baseline at $sharedDocBaselinePath — record it with '
            '`dart run bin/check_spec_tree_duplication.dart --record`',
      );

      final shared = sharedSpecTreeDocs(containerRoot);
      final added = shared.difference(readSharedDocBaseline(baselineFile));

      expect(
        added.toList()..sort(),
        isEmpty,
        reason:
            'each line above is now stated in BOTH spec trees. The reviewer '
            'is documentation-gated and the editor is not, so the copies will '
            'drift and nothing will say so. Move the rule it explains to '
            '`tom_som_dart_runtime` and have both trees cite it.',
      );
    });
  });

  group('STD2: what counts as a shared explanation', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('spec_tree_dup_'));
    tearDown(() => root.deleteSync(recursive: true));

    Directory writeTree(String name, List<String> lines) {
      final dir = Directory(p.join(root.path, name))
        ..createSync(recursive: true);
      File(p.join(dir.path, 'a.dart')).writeAsStringSync(lines.join('\n'));
      return dir;
    }

    test('a long doc line is collected; a short one is not', () {
      final long = '/// ${'x' * (sharedDocMinLength + 1)}';
      final short = '/// ${'y' * (sharedDocMinLength - 1)}';
      final lines = docCommentLines(writeTree('t', [long, short]));
      expect(lines, hasLength(1));
      expect(lines.single, 'x' * (sharedDocMinLength + 1));
    });

    test('the threshold is exclusive — exactly N characters is ignored', () {
      // Pinned because "over" and "at least" differ by one line, and a
      // re-recorded baseline would absorb the difference silently.
      final at = '/// ${'x' * sharedDocMinLength}';
      expect(docCommentLines(writeTree('t', [at])), isEmpty);
    });

    test('indentation is not part of the statement', () {
      final text = 'z' * (sharedDocMinLength + 1);
      final a = docCommentLines(writeTree('a', ['/// $text']));
      final b = docCommentLines(writeTree('b', ['      /// $text']));
      expect(a.intersection(b), hasLength(1));
    });

    test('ordinary comments and code are not doc lines', () {
      final text = 'w' * (sharedDocMinLength + 1);
      expect(
        docCommentLines(writeTree('t', ['// $text', 'final s = "$text";'])),
        isEmpty,
      );
    });

    test('non-Dart files are not scanned', () {
      final dir = Directory(p.join(root.path, 'md'))..createSync();
      File(p.join(dir.path, 'a.md')).writeAsStringSync('/// ${'q' * 60}');
      expect(docCommentLines(dir), isEmpty);
    });

    test('a missing tree yields the empty set rather than throwing', () {
      expect(docCommentLines(Directory(p.join(root.path, 'absent'))), isEmpty);
    });

    test('the baseline round-trips, ignoring comments and blanks', () {
      final lines = {'a' * 60, 'b' * 60};
      final file = File(p.join(root.path, 'baseline.txt'));
      writeSharedDocBaseline(file, lines);
      expect(readSharedDocBaseline(file), lines);
      expect(
        file.readAsStringSync(),
        contains('#'),
        reason: 'the header explains why the file exists to whoever hits it',
      );
    });

    test('the baseline is written sorted, so a diff shows what changed', () {
      final file = File(p.join(root.path, 'baseline.txt'));
      writeSharedDocBaseline(file, {'c' * 60, 'a' * 60, 'b' * 60});
      final records = file
          .readAsLinesSync()
          .where((l) => l.isNotEmpty && !l.startsWith('#'))
          .toList();
      expect(records, ['a' * 60, 'b' * 60, 'c' * 60]);
    });
  });
}
