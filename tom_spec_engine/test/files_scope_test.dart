import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 8 (`d4rt_and_llm_tools_plan.md`) / §7: the `files` base scope and its
/// audited [SpecFileFacade].
///
/// Policy: **read = any path**, **write = whitelist only** (default
/// `agent/scratchpad`). Enforcement is path canonicalisation (resolving
/// symlinks / `..` to block escapes) so any write outside the whitelist raises
/// [FilePermissionError] *before* touching disk; the `files` scope additionally
/// grants the D4rt permission system `read=any` + `write=<whitelist>` as a
/// defence-in-depth backstop.

void main() {
  late Directory ws; // the spec workspace root
  late Directory outside; // a sibling dir OUTSIDE the workspace
  late SpecFileFacade facade;

  setUp(() {
    ws = Directory.systemTemp.createTempSync('tse_files_ws_');
    outside = Directory.systemTemp.createTempSync('tse_files_out_');
    facade = SpecFileFacade(workspaceRoot: ws.path);
  });

  tearDown(() {
    if (ws.existsSync()) ws.deleteSync(recursive: true);
    if (outside.existsSync()) outside.deleteSync(recursive: true);
  });

  /// Runs [source] under a `files` scope bound to [facade].
  Object? run(String source) {
    final env = (ScopeRegistry()..register(filesScope(facade))).build(['files']);
    final d4rt = D4rt();
    env.applyTo(d4rt);
    return d4rt.execute(source: source);
  }

  const importFiles = "import 'package:tom_spec_engine/spec_files.dart';";

  group('facade defaults', () {
    test('default writable root is <workspace>/agent/scratchpad', () {
      expect(facade.writableRoots, hasLength(1));
      expect(
        facade.writableRoots.single,
        endsWith('${Platform.pathSeparator}agent'
            '${Platform.pathSeparator}scratchpad'),
      );
    });
  });

  group('read = any path', () {
    test('reads a file outside the workspace', () {
      final secret = File('${outside.path}/secret.txt')
        ..writeAsStringSync('top secret');
      expect(facade.readText(secret.path), 'top secret');
      expect(facade.exists(secret.path), isTrue);
      expect(facade.readLines(secret.path), ['top secret']);
    });

    test('a script reads any path through the facade', () {
      File('${outside.path}/data.txt').writeAsStringSync('via script');
      final read = run('''
$importFiles
main() => files.readText(r'${outside.path}/data.txt');
''');
      expect(read, 'via script');
    });
  });

  group('write = whitelist only', () {
    test('writes under agent/scratchpad succeed (parent auto-created)', () {
      facade.writeText('agent/scratchpad/note.txt', 'hello');
      expect(
        File('${ws.path}/agent/scratchpad/note.txt').readAsStringSync(),
        'hello',
      );
    });

    test('a write outside the whitelist throws before touching disk', () {
      expect(
        () => facade.writeText('project.txt', 'nope'),
        throwsA(isA<FilePermissionError>()),
      );
      expect(File('${ws.path}/project.txt').existsSync(), isFalse);
    });

    test('a `..` escape is canonicalised and rejected before disk', () {
      // scratchpad/../escape.txt resolves to <ws>/agent/escape.txt — outside.
      expect(
        () => facade.writeText('agent/scratchpad/../escape.txt', 'x'),
        throwsA(isA<FilePermissionError>()),
      );
      expect(File('${ws.path}/agent/escape.txt').existsSync(), isFalse);
    });

    test('a symlink that points out of the whitelist is rejected', () {
      Directory('${ws.path}/agent/scratchpad').createSync(recursive: true);
      Link('${ws.path}/agent/scratchpad/out').createSync(outside.path);
      expect(
        () => facade.writeText('agent/scratchpad/out/evil.txt', 'x'),
        throwsA(isA<FilePermissionError>()),
      );
      expect(File('${outside.path}/evil.txt').existsSync(), isFalse);
    });

    test('append / createDir / delete / copy / move honour the whitelist', () {
      facade.createDir('agent/scratchpad/sub');
      expect(Directory('${ws.path}/agent/scratchpad/sub').existsSync(), isTrue);

      facade.writeText('agent/scratchpad/sub/a.txt', 'a');
      facade.append('agent/scratchpad/sub/a.txt', 'b');
      expect(
        File('${ws.path}/agent/scratchpad/sub/a.txt').readAsStringSync(),
        'ab',
      );

      // copy: source may be anywhere (read), dest must be writable.
      final src = File('${outside.path}/src.txt')..writeAsStringSync('copied');
      facade.copy(src.path, 'agent/scratchpad/sub/copy.txt');
      expect(
        File('${ws.path}/agent/scratchpad/sub/copy.txt').readAsStringSync(),
        'copied',
      );
      // copy out of the whitelist is rejected.
      expect(
        () => facade.copy(src.path, '${outside.path}/leak.txt'),
        throwsA(isA<FilePermissionError>()),
      );

      facade.delete('agent/scratchpad/sub/a.txt');
      expect(
        File('${ws.path}/agent/scratchpad/sub/a.txt').existsSync(),
        isFalse,
      );
      // delete outside the whitelist is rejected.
      final keep = File('${outside.path}/keep.txt')..writeAsStringSync('keep');
      expect(
        () => facade.delete(keep.path),
        throwsA(isA<FilePermissionError>()),
      );
      expect(keep.existsSync(), isTrue);
    });
  });

  group('files scope', () {
    test('is named "files" and grants read-any + write-scratchpad', () {
      final scope = filesScope(facade);
      expect(scope.name, 'files');
      expect(scope.libraries.map((l) => l.name), contains('spec_files'));
      // read=any grant present.
      expect(
        scope.grants.any((g) => g.toString() == FilesystemPermission.read.toString()),
        isTrue,
      );
      // a writePath grant for the scratchpad present.
      expect(
        scope.grants.any((g) =>
            g.toString() ==
            FilesystemPermission.writePath(facade.writableRoots.single)
                .toString()),
        isTrue,
      );
    });

    test('a script writes under the whitelist', () {
      run('''
$importFiles
main() { files.writeText('agent/scratchpad/s.txt', 'from script'); }
''');
      expect(
        File('${ws.path}/agent/scratchpad/s.txt').readAsStringSync(),
        'from script',
      );
    });

    test('a script write outside the whitelist surfaces as an error', () {
      expect(
        () => run('''
$importFiles
main() { files.writeText('outside.txt', 'x'); }
'''),
        throwsA(anything),
      );
      expect(File('${ws.path}/outside.txt').existsSync(), isFalse);
    });

    test('a script find can include the declared asset dirs (item 18)', () {
      // An out-of-workspace asset dir the profile declares.
      File('${outside.path}/template.md').writeAsStringSync('# tmpl');
      final assetFacade = SpecFileFacade(
        workspaceRoot: ws.path,
        assetDirs: [outside.path],
      );
      File('${ws.path}/local.md').writeAsStringSync('# local');

      Object? runWith(String source) {
        final env =
            (ScopeRegistry()..register(filesScope(assetFacade))).build(['files']);
        final d4rt = D4rt();
        env.applyTo(d4rt);
        return d4rt.execute(source: source);
      }

      final found = runWith('''
$importFiles
main() => files.find('.', glob: '*.md', includeAssets: true);
''') as List;
      final names = found.map((p) => (p as String).split('/').last).toSet();
      expect(names, containsAll(['local.md', 'template.md']));
    });
  });
}
