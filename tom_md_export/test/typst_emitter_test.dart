// The Typst emitter, construct by construct: escaping, headings and labels,
// links, lists, quotes, code, tables, the reading notation's divs, spans and
// citations (styled, unknown, switched off), review annotations kept as text,
// and the options (outline, kind styles).
import 'package:test/test.dart';
import 'package:tom_md_export/tom_md_export.dart';

String typst(String md, {TypstOptions options = const TypstOptions()}) =>
    TypstEmitter(
      options,
    ).emit(MarkdownReader(notation: options.notation).parse(md));

/// The content after the setup and the kind styles.
String body(String md, {TypstOptions options = const TypstOptions()}) {
  final all = typst(md, options: options);
  return all.substring(
    all.indexOf(options.kindStyles) + options.kindStyles.length,
  );
}

void main() {
  group('text', () {
    test('every character markup gives a meaning is escaped', () {
      expect(
        escapeMarkup(
          r'*_`$#[]<>@~/=-+.:"'
          "'"
          r'\ abc 1.',
        ),
        r'\*\_\`\$\#\[\]\<\>\@\~\/\=\-\+\.\:\"'
        r"\'"
        r'\\ abc 1\.',
      );
    });

    test('a paragraph is escaped text', () {
      expect(body('A *b* -- c // d'), contains(r'A #emph[b]; \-\- c \/\/ d'));
    });
  });

  group('headings', () {
    test('level and label; the heading div of depth 8 too', () {
      final t = body(
        '## <a id="SBP"></a> Blueprint\n\n'
        '<div class="heading8"><a id="X-1"></a> Deep</div>',
      );
      expect(t, contains('== Blueprint <SBP>'));
      expect(t, contains('======== Deep <X-1>'));
    });

    test('a label defined twice is neither set nor linked', () {
      final t = body(
        '# <a id="A"></a> One\n\n# <a id="A"></a> Two\n\n[to A](#A)',
      );
      expect(t, isNot(contains('<A>')));
      expect(t, contains(r'#link("#A")[to A];'));
    });
  });

  group('links', () {
    test('within the document, to another file, outward', () {
      final t = body(
        '# <a id="T"></a> T\n\n[here](#T) [self](doc.tomspecs.md#T) '
        '[there](other.md#T) [web](https://typst.app)',
        options: const TypstOptions(documentNames: {'doc.tomspecs.md'}),
      );
      expect(t, contains('#link(<T>)[here];'));
      expect(t, contains('#link(<T>)[self];'));
      expect(t, contains('#link("other.md#T")[there];'));
      expect(t, contains('#link("https://typst.app")[web];'));
    });

    test('an anchor in text becomes a labelled metadata point', () {
      expect(body('<a id="P"></a>point'), contains('#metadata(none) <P>point'));
    });
  });

  group('blocks', () {
    test('bullet and ordered lists, nested', () {
      final t = body('- a\n  - b\n\n3. c\n');
      expect(
        t,
        contains('#list(tight: true, [a\n\n#list(tight: true, [b]);]);'),
      );
      expect(t, contains('#enum(start: 3, tight: true, [c]);'));
    });

    test('a quote, a code block with its language, a rule', () {
      final t = body('> quoted\n\n```dart\nmain() {}\n```\n\n---\n');
      expect(t, contains('#quote(block: true)[quoted];'));
      expect(t, contains('#raw(block: true, lang: "dart", "main() {}");'));
      expect(t, contains('#line(length: 100%'));
    });

    test('a code span is a raw string, its quotes escaped', () {
      expect(body(r'`a "b" \c`'), contains(r'#raw("a \"b\" \\c");'));
    });
  });

  group('tables', () {
    test(
      'a form table: short field column, the value column takes the rest',
      () {
        final t = body(
          '| TomSpecField | Value |\n| --- | --- |\n| Status | approved |',
        );
        expect(t, contains('columns: (auto, 1fr),'));
        expect(t, contains('table.header([TomSpecField], [Value]),'));
        expect(t, contains('[Status], [approved],'));
      },
    );

    test(
      'a record table with long columns shares the width; alignment kept',
      () {
        final long = 'word ' * 20;
        final t = body(
          '| Id | Given | When |\n| --- | :-: | --: |\n| A | $long | $long |',
        );
        expect(t, contains('columns: (auto, '));
        expect(RegExp(r'columns: \(auto, \d+fr, \d+fr\)').hasMatch(t), isTrue);
        expect(t, contains('align: (left, center, right),'));
      },
    );
  });

  group('the reading notation', () {
    test('a known kind is a styled block, an unknown one plain content', () {
      final t = body(
        '::: {.provenance}\nsource\n:::\n\n::: {.custom}\nplain\n:::',
      );
      expect(t, contains('#tm-block("provenance", [source]);'));
      expect(t, isNot(contains('"custom"')));
      expect(t, contains('plain'));
    });

    test('records and refs are blocks of their kind', () {
      final t = body('::: {.refs}\n[A](#A)\n:::');
      expect(t, contains('#tm-block("refs", ['));
    });

    test('a span and the three citation shapes', () {
      final t = body('a [note]{.aside} b (-> C2.1) c (<- n.md) d (<~ i.md)');
      expect(t, contains('#tm-span("aside", [note]);'));
      expect(t, contains(r'#tm-cite("trace", "->", [C2\.1]);'));
      expect(t, contains(r'#tm-cite("provenance", "<-", [n\.md]);'));
      expect(t, contains(r'#tm-cite("provenance", "<~", [i\.md]);'));
    });

    test('with the notation off it is written as it stands', () {
      final t = body(
        '::: {.aside}\nx (-> C1)\n:::',
        options: const TypstOptions(notation: false, kindStyles: noKindStyles),
      );
      expect(t, isNot(contains('#tm-')));
      expect(t, contains(r'\:\:\: {\.aside}'));
      expect(t, contains(r'x (\-\> C1)'));
    });

    test('review annotations kept are text', () {
      final t = body('a {~~old~>new~~}{@agent 2026-11-21} b');
      expect(t, contains(r'{\~\~old\~\>new\~\~}{\@agent 2026\-11\-21} b'));
    });
  });

  group('options', () {
    test('the outline opens the document unless switched off', () {
      expect(typst('# T'), contains('#outline(depth: 3);'));
      expect(
        typst('# T', options: const TypstOptions(outline: false)),
        isNot(contains('#outline')),
      );
    });

    test('kind styles replace the built-in ones', () {
      const mine = '#let tm-block(kind, body) = body // mine';
      final t = typst('# T', options: const TypstOptions(kindStyles: mine));
      expect(t, contains(mine));
      expect(t, isNot(contains('tm-muted')));
    });
  });
}
