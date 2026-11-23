// The Markdown reader, construct by construct: headings (ATX and the styled
// heading divs), paragraphs, inlines, lists, quotes, fenced code, GFM tables
// and the reading notation (divs, spans, citation shapes), with the notation
// switched off as well.
import 'package:test/test.dart';
import 'package:tom_md_export/tom_md_export.dart';

List<MdBlock> read(String md, {bool notation = true}) =>
    MarkdownReader(notation: notation).parse(md);

List<MdInline> inlines(String md) => (read(md).single as MdParagraph).text;

void main() {
  group('headings', () {
    test('ATX levels 1–6, closing hashes dropped', () {
      final b = read('# One\n\n###### Six ##\n');
      expect((b[0] as MdHeading).level, 1);
      expect(mdPlainText((b[0] as MdHeading).text), 'One');
      expect((b[1] as MdHeading).level, 6);
      expect(mdPlainText((b[1] as MdHeading).text), 'Six');
    });

    test('the anchor and the id comment of a rendition heading', () {
      final h =
          read('### <!--[DAENT-ENTI-GRANT]--> <a id="DAENT-ENTI-GRANT"></a> Grant')
                  .single
              as MdHeading;
      expect(h.anchors, ['DAENT-ENTI-GRANT']);
      expect(mdPlainText(h.text), 'Grant');
    });

    test('a styled heading div of any depth', () {
      final h =
          read(
                '<div class="heading9" style="font-weight:bold">'
                '<!--[RQDEP-ITEM-1]--> <a id="RQDEP-ITEM-1"></a> Dependency 1</div>',
              ).single
              as MdHeading;
      expect(h.level, 9);
      expect(h.anchors, ['RQDEP-ITEM-1']);
      expect(mdPlainText(h.text), 'Dependency 1');
    });
  });

  group('paragraphs and inlines', () {
    test('lines join with a space; two trailing spaces break the line', () {
      final xs = inlines('first\nsecond  \nthird');
      expect(mdPlainText(xs), 'first second third');
      expect(xs.whereType<MdLineBreak>(), hasLength(1));
    });

    test('emphasis, strong, code span, escapes', () {
      final xs = inlines(r'*a* **b** _c_ `x|y` \*lit\* snake_case_name');
      expect(xs.whereType<MdEmphasis>(), hasLength(2));
      expect(xs.whereType<MdStrong>(), hasLength(1));
      expect(xs.whereType<MdCodeSpan>().single.code, 'x|y');
      expect(mdPlainText(xs), contains('*lit*'));
      expect(mdPlainText(xs), contains('snake_case_name'));
    });

    test('links, autolinks and anchors', () {
      final xs = inlines(
        '[Grant](#DAENT-ENTI-GRANT) <https://typst.app> '
        '<a id="DATAA-CONS-ROLE"></a>id [x](other.md#A "title")',
      );
      final links = xs.whereType<MdLink>().toList();
      expect(links.map((l) => l.url), [
        '#DAENT-ENTI-GRANT',
        'https://typst.app',
        'other.md#A',
      ]);
      expect(xs.whereType<MdAnchor>().single.id, 'DATAA-CONS-ROLE');
    });

    test('an HTML comment in text is dropped', () {
      expect(mdPlainText(inlines('a <!-- note --> b')), 'a  b');
    });
  });

  group('lists', () {
    test('nested bullets with continuation lines', () {
      final l = read('- one\n  wrapped\n  - inner\n- two\n').single as MdList;
      expect(l.ordered, isFalse);
      expect(l.items, hasLength(2));
      expect(mdPlainText((l.items[0][0] as MdParagraph).text), 'one wrapped');
      expect((l.items[0][1] as MdList).items, hasLength(1));
    });

    test('an ordered list keeps its start', () {
      final l = read('3. c\n4. d\n').single as MdList;
      expect(l.ordered, isTrue);
      expect(l.start, 3);
      expect(l.items, hasLength(2));
    });
  });

  group('quotes and code', () {
    test('a review annotation block is a quote', () {
      final q =
          read('> **❓ DQ-1 — topic:** text\n>\n> **Answer:**').single
              as MdQuote;
      expect(q.blocks, hasLength(2));
    });

    test('a fenced code block keeps its language and lines', () {
      final c = read('```mermaid\ngraph TD\n  A-->B\n```').single as MdCode;
      expect(c.language, 'mermaid');
      expect(c.text, 'graph TD\n  A-->B');
    });
  });

  group('tables', () {
    test('header, alignments, escaped pipes and code spans with pipes', () {
      final t =
          read(
                '| Id | Value |\n| :-- | --: |\n'
                r'| a \| b | `x|y` |'
                '\n| short |\n',
              ).single
              as MdTable;
      expect(t.aligns, [MdAlign.left, MdAlign.right]);
      expect(mdPlainText(t.rows[0][0]), 'a | b');
      expect((t.rows[0][1].single as MdCodeSpan).code, 'x|y');
      expect(t.rows[1], hasLength(2), reason: 'padded to the header');
    });

    test('a records div around a table', () {
      final d =
          read(
                '::: {.records}\n| Id | When |\n| --- | --- |\n| A | B |\n:::',
              ).single
              as MdDiv;
      expect(d.kind, 'records');
      expect(d.blocks.single, isA<MdTable>());
    });
  });

  group('the reading notation', () {
    test('a div: braces with attributes, or a bare kind word', () {
      final d =
          read('::: {.provenance label="Source"}\ntext\n:::').single as MdDiv;
      expect(d.kind, 'provenance');
      expect(d.attributes, {'label': 'Source'});
      expect((read('::: aside\nx\n:::').single as MdDiv).kind, 'aside');
    });

    test('nested divs, and a fence inside a div is literal', () {
      final d =
          read(
                ':::: {.editorial}\n::: {.aside}\ninner\n:::\n'
                '```\n:::\n```\n::::',
              ).single
              as MdDiv;
      expect(d.blocks[0], isA<MdDiv>());
      expect((d.blocks[1] as MdCode).text, ':::');
    });

    test('an unclosed div closes at the next heading', () {
      final b = read('::: {.aside}\nopen\n## Next\n');
      expect(b[0], isA<MdDiv>());
      expect(b[1], isA<MdHeading>());
    });

    test('a span with its kind', () {
      final s = inlines('see [a note]{.aside} here').whereType<MdSpan>().single;
      expect(s.kind, 'aside');
      expect(mdPlainText(s.children), 'a note');
    });

    test('the three citation shapes; parentheses inside balance', () {
      final xs = inlines(
        'a (-> C2.1, FR-12) b (<- notes.md#X) c (<~ iterations/s(1).md) '
        'd (->no space) e (SHA-256)',
      );
      final cs = xs.whereType<MdCitation>().toList();
      expect(cs.map((c) => c.shape), [
        MdCitationShape.backedBy,
        MdCitationShape.takenFrom,
        MdCitationShape.extrapolatedFrom,
      ]);
      expect(cs.map((c) => c.content), [
        'C2.1, FR-12',
        'notes.md#X',
        'iterations/s(1).md',
      ]);
      expect(mdPlainText(xs), contains('(->no space)'));
      expect(mdPlainText(xs), contains('(SHA-256)'));
    });

    test('with the notation off, fences, spans and citations are text', () {
      final b = read(
        '::: {.aside}\nx (-> C1) [y]{.aside}\n:::',
        notation: false,
      );
      expect(b.single, isA<MdParagraph>());
      final text = mdPlainText((b.single as MdParagraph).text);
      expect(text, contains('::: {.aside}'));
      expect(text, contains('(-> C1)'));
      expect(text, contains('[y]{.aside}'));
    });

    test('the docspec and readable headers are dropped', () {
      final b = read(
        '<!-- docspec: x/1 -->\n<!-- readable: headings=divs -->\n# T',
      );
      expect(b.single, isA<MdHeading>());
    });
  });
}
