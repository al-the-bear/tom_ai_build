import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_spec_engine/tom_spec_engine.dart';

/// Step 14 (`d4rt_and_llm_tools_plan.md`) / §8.2 — the **file** tools:
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
  });
}
