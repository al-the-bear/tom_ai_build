/// The heading structure of the DocSpecs specification's reading forms:
/// styled `heading<N>` divs, section anchors, fenced code, skipped levels and
/// the line of a section's text.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_scanner/tom_doc_scanner.dart';

/// [md] scanned as a file of a scratch folder.
Document scan(String md) {
  final dir = Directory.systemTemp.createTempSync('reading_structure');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File(p.join(dir.path, 'doc.md'))..writeAsStringSync(md);
  return DocScanner.scanDocumentSync(
    filepath: file.path,
    workspaceRoot: dir.path,
  );
}

const _style =
    'style="margin:1em 0 0.5em;padding-left:0.75em;font-weight:bold"';

void main() {
  group('styled-div headings', () {
    test('a heading7 div reads as a level-7 heading', () {
      final parsed = MarkdownParser.parseHeadlines(
        '<div class="heading7" $_style><!--[ACE-CRIT-1]--> Second '
        'administrator &amp; &lt;deputy&gt;</div>\n',
      );
      expect(parsed, hasLength(1));
      final h = parsed.single.$1;
      expect(h.level, 7);
      expect(h.explicitId, 'ACE-CRIT-1');
      expect(h.text, 'Second administrator & <deputy>');
    });

    test('a level of two digits reads as well', () {
      final h = MarkdownParser.parseHeadlines(
        '<div class="heading12"><!--[X-1]--> Deep</div>',
      ).single.$1;
      expect(h.level, 12);
    });

    test('key=value fields in the id comment are read', () {
      final h = MarkdownParser.parseHeadlines(
        '<div class="heading8" $_style><!--[A-1] tags=urgent--> T</div>',
      ).single.$1;
      expect(h.fields, {'tags': 'urgent'});
    });

    test('a heading6 div, an attribute before class, or a div over two lines '
        'is content', () {
      expect(
        MarkdownParser.parseHeadlines(
          '<div class="heading6"><!--[A-1]--> T</div>\n'
          '<div style="x" class="heading7"><!--[A-2]--> T</div>\n'
          '<div class="heading7"><!--[A-3]--> T\n'
          '</div>\n'
          ' <div class="heading7"><!--[A-4]--> T</div>\n',
        ),
        isEmpty,
      );
    });

    test('a styled-div heading nests under the nearest shallower heading', () {
      final doc = scan(
        '# <!--[D00]--> Doc\n'
        '\n'
        '## <!--[GOALS]--> Goals\n'
        '\n'
        '<div class="heading7" $_style><!--[GOAL-ITEM-1]--> Goal 1</div>\n'
        '\n'
        'First goal.\n'
        '\n'
        '<div class="heading7" $_style><!--[GOAL-ITEM-2]--> Goal 2</div>\n'
        '\n'
        'Second goal.\n'
        '\n'
        '## <!--[NEXT]--> Next\n',
      );
      final goals = doc.sections!.first;
      expect(goals.id, 'GOALS');
      expect(goals.sections!.map((s) => s.id), ['GOAL-ITEM-1', 'GOAL-ITEM-2']);
      expect(goals.sections!.first.text, 'First goal.');
      expect(doc.sections!.map((s) => s.id), ['GOALS', 'NEXT']);
    });
  });

  group('section anchors', () {
    test("a heading's own anchor is removed from its title", () {
      final h = MarkdownParser.parseHeadlines(
        '### <!--[DAENT-ENTI-GRANT]--> <a id="DAENT-ENTI-GRANT"></a> Grant',
      ).single.$1;
      expect(h.text, 'Grant');
    });

    test("a styled-div heading's own anchor is removed too", () {
      final h = MarkdownParser.parseHeadlines(
        '<div class="heading7" $_style><!--[ACE-CRIT-1]--> '
        '<a id="ACE-CRIT-1"></a> Second administrator</div>',
      ).single.$1;
      expect(h.text, 'Second administrator');
    });

    test('an anchor naming another id is ordinary text', () {
      final h = MarkdownParser.parseHeadlines(
        '## <!--[A-1]--> <a id="B-2"></a> Title',
      ).single.$1;
      expect(h.text, '<a id="B-2"></a> Title');
    });
  });

  group('fenced code', () {
    test('no line inside a fence is a heading', () {
      final parsed = MarkdownParser.parseHeadlines(
        '## <!--[A]--> A\n'
        '```markdown\n'
        '## <!--[NOT]--> Not a heading\n'
        '<div class="heading7"><!--[NOT-2]--> Nor this</div>\n'
        '```\n'
        '~~~~\n'
        '# Also not\n'
        '~~~\n'
        '# Still inside the four-tilde fence\n'
        '~~~~\n'
        '## <!--[B]--> B\n',
      );
      expect(parsed.map((h) => h.$1.explicitId), ['A', 'B']);
    });

    test('the fenced lines stay in the section text', () {
      final doc = scan(
        '# Doc\n\n## <!--[A]--> A\n\n```\n# code\n```\n\n## <!--[B]--> B\n',
      );
      expect(doc.sections!.first.text, '```\n# code\n```');
    });
  });

  group('section tree', () {
    test('a skipped level nests under the nearest shallower heading', () {
      final doc = scan(
        '# Doc\n\n## <!--[A]--> A\n\n#### <!--[A-DEEP]--> Deep\n\nDeep text.\n'
        '\n### <!--[A-MID]--> Mid\n\n## <!--[B]--> B\n',
      );
      final a = doc.sections!.first;
      expect(a.text, isEmpty);
      expect(a.sections!.map((s) => s.id), ['A-DEEP', 'A-MID']);
      expect(a.sections!.first.text, 'Deep text.');
      expect(doc.sections!.map((s) => s.id), ['A', 'B']);
    });
  });

  group('textLineNumber', () {
    test('is the line of the first text line, null without text', () {
      final doc = scan(
        '<!-- docspec: demo/1.0 -->\n' // 1
        '# <!--[D00]--> Doc\n' // 2
        '\n' // 3
        'Intro.\n' // 4
        '## <!--[A]--> A\n' // 5
        '\n' // 6
        '\n' // 7
        'Line one.\n' // 8
        'Line two.\n' // 9
        '## <!--[B]--> B\n', // 10
      );
      expect(doc.textLineNumber, 4);
      expect(doc.sections![0].textLineNumber, 8);
      expect(doc.sections![0].text.split('\n')[1], 'Line two.');
      expect(doc.sections![1].textLineNumber, isNull);
    });

    test('survives a JSON round trip', () {
      final doc = scan('# Doc\n\n## <!--[A]--> A\n\nText.\n');
      final back = Section.fromJson(doc.sections!.first.toJson());
      expect(back.textLineNumber, 5);
    });
  });
}
