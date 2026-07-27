import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// `llm_and_d4rt_tools.md` §8.2 — the **file** tools:
/// `file_read(path)`, `file_find(glob)`, and `file_write(path, content)` over
/// the audited [SpecFileFacade] (§7). Each returns compact JSON; a write outside
/// the whitelist is reported as a failed result, never a thrown stack.
void main() {
  late Directory ws;
  late SpecFileFacade facade;
  late FileTools tools;

  setUp(() {
    ws = Directory.systemTemp.createTempSync('tse_file_tools_');
    facade = SpecFileFacade(workspaceRoot: ws.path, writableDirs: const ['scratch']);
    tools = FileTools(facade);
  });

  tearDown(() {
    if (ws.existsSync()) ws.deleteSync(recursive: true);
  });

  group('file_write + file_read', () {
    test('writes to the whitelist then reads it back (compact JSON)', () {
      final written = tools.write('scratch/notes.txt', 'hello tools');
      expect(written.ok, isTrue);
      expect(written.toJson()['ok'], isTrue);

      final read = tools.read('scratch/notes.txt');
      expect(read.exists, isTrue);
      expect(read.content, 'hello tools');
      expect(read.toJson()['content'], 'hello tools');
    });

    test('reading a missing file reports exists:false', () {
      final read = tools.read('scratch/absent.txt');
      expect(read.exists, isFalse);
      expect(read.content, isNull);
      expect(read.toJson()['exists'], isFalse);
    });

    test('a write outside the whitelist is a failed result, not a throw', () {
      final result = tools.write('forbidden/x.txt', 'nope');
      expect(result.ok, isFalse);
      expect(result.error, contains('outside'));
      expect(result.toJson()['ok'], isFalse);
      // Nothing was written.
      expect(File('${ws.path}/forbidden/x.txt').existsSync(), isFalse);
    });
  });

  group('file_find', () {
    test('finds files by basename glob', () {
      tools.write('scratch/a.md', '# a');
      tools.write('scratch/b.md', '# b');
      tools.write('scratch/c.txt', 'c');

      final found = tools.find('*.md');
      expect(found.matches.where((p) => p.endsWith('a.md')), isNotEmpty);
      expect(found.matches.where((p) => p.endsWith('b.md')), isNotEmpty);
      expect(found.matches.where((p) => p.endsWith('c.txt')), isEmpty);
      expect(found.toJson()['glob'], '*.md');
    });

    test('a `?` glob matches a single character (richer glob, item 18)', () {
      tools.write('scratch/r1.txt', '1');
      tools.write('scratch/r2.txt', '2');
      tools.write('scratch/r42.txt', '42');

      final found = tools.find('r?.txt');
      final names = found.matches.map((p) => p.split('/').last).toSet();
      expect(names, containsAll(['r1.txt', 'r2.txt']));
      expect(names, isNot(contains('r42.txt')));
    });

    test('a `[...]` character class and `{a,b}` alternation match (item 18)', () {
      tools.write('scratch/a.dart', 'a');
      tools.write('scratch/b.dart', 'b');
      tools.write('scratch/c.dart', 'c');

      final cls = tools.find('[ab].dart').matches.map((p) => p.split('/').last);
      expect(cls.toSet(), {'a.dart', 'b.dart'});

      final alt =
          tools.find('{a,c}.dart').matches.map((p) => p.split('/').last);
      expect(alt.toSet(), {'a.dart', 'c.dart'});
    });

    test('a glob with `/` matches the path relative to the search root, and '
        '`**` crosses directories (item 18)', () {
      tools.write('scratch/top.md', 'top');
      tools.write('scratch/sub/deep.md', 'deep');
      tools.write('scratch/sub/inner/leaf.md', 'leaf');

      // `**/*.md` reaches every depth (path-relative match).
      final deep = tools.find('**/*.md', dir: 'scratch').matches;
      final deepNames = deep.map((p) => p.split('/').last).toSet();
      expect(deepNames, containsAll(['top.md', 'deep.md', 'leaf.md']));

      // `sub/*.md` matches only the one level under sub (single-segment `*`).
      final oneLevel = tools.find('sub/*.md', dir: 'scratch').matches;
      final oneNames = oneLevel.map((p) => p.split('/').last).toSet();
      expect(oneNames, contains('deep.md'));
      expect(oneNames, isNot(contains('leaf.md')));
      expect(oneNames, isNot(contains('top.md')));
    });
  });

  group('file_find includeAssets (item 18)', () {
    test('searches the declared asset dirs and returns the de-duplicated union',
        () {
      // The asset directory lives OUTSIDE the workspace root, so a default
      // workspace walk never reaches it — only includeAssets does.
      final assets = Directory.systemTemp.createTempSync('tse_assets_');
      addTearDown(() {
        if (assets.existsSync()) assets.deleteSync(recursive: true);
      });
      File('${assets.path}/template.md').writeAsStringSync('# tmpl');
      final f = SpecFileFacade(
        workspaceRoot: ws.path,
        writableDirs: const ['scratch'],
        assetDirs: [assets.path],
      );
      final t = FileTools(f);
      t.write('scratch/local.md', '# local');

      // Without includeAssets, only the workspace search root is walked.
      final localOnly = t.find('*.md').matches.map((p) => p.split('/').last);
      expect(localOnly, contains('local.md'));
      expect(localOnly, isNot(contains('template.md')));

      // With includeAssets, the out-of-workspace asset dir is also enumerated.
      final withAssets =
          t.find('*.md', includeAssets: true).matches.map((p) => p.split('/').last);
      expect(withAssets, containsAll(['local.md', 'template.md']));
    });
  });
}
